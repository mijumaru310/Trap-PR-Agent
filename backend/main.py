from fastapi import FastAPI, HTTPException, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from github import Github
from github import Auth
import os
from dotenv import load_dotenv

from google import genai
from google.genai import types
import json
import asyncio
import threading
from ai_service import generate_structured_response, get_ai_credentials

# 既存のインポートに加えて以下を追記
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from datetime import datetime
# .envファイルから環境変数を読み込む
load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins for local testing
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_github_client(request_headers: dict) -> Github:
    token = request_headers.get("x-github-token") or os.getenv("GITHUB_TOKEN")
    if not token:
        raise HTTPException(status_code=400, detail="GITHUB_TOKENが設定されていません。アプリの設定画面から入力するか、サーバーの.envファイルを確認してください。")
    return Github(auth=Auth.Token(token))

# Firebaseの初期化
# backend/firebase-key.json を読み込みます
cred = credentials.Certificate("firebase-key.json")
firebase_admin.initialize_app(cred)

# Firestoreクライアントの取得
db = firestore.client()

# =============================================================================
# 言語自動判定マッピング
# =============================================================================
EXTENSION_LANGUAGE_MAP = {
    ".py": "python",
    ".js": "javascript",
    ".ts": "typescript",
    ".jsx": "javascript",
    ".tsx": "typescript",
    ".java": "java",
    ".c": "c",
    ".h": "c",
    ".cpp": "c++",
    ".cc": "c++",
    ".cs": "c#",
    ".go": "go",
    ".rb": "ruby",
    ".php": "php",
    ".rs": "rust",
    ".swift": "swift",
    ".kt": "kotlin",
    ".dart": "dart",
    ".html": "html",
    ".css": "css",
    ".sql": "sql",
    ".sh": "bash",
    ".yaml": "yaml",
    ".yml": "yaml",
    ".json": "json",
    ".xml": "xml",
    ".r": "r",
    ".scala": "scala",
    ".lua": "lua",
    ".pl": "perl",
    ".m": "objective-c",
    ".vue": "vue",
    ".svelte": "svelte",
}

def detect_language(file_path: str) -> str:
    """ファイルパスの拡張子からプログラミング言語を自動判定する"""
    _, ext = os.path.splitext(file_path)
    return EXTENSION_LANGUAGE_MAP.get(ext.lower(), "unknown")


# =============================================================================
# ポーリングによる自動コメント検知用の辞書
# =============================================================================
active_watchers: dict[str, bool] = {}

@app.get("/")
def read_root():
    return {"message": "Trap-PR Agent API is running!"}

@app.get("/api/v1/github/test/{owner}/{repo}")
def test_github_connection(owner: str, repo: str):
    """
    指定したリポジトリの情報を取得するテストエンドポイント
    """
    try:
        # リポジトリの取得 (例: "tiangolo/fastapi")
        provider, api_key = get_ai_credentials(dict(request.headers))
        g = get_github_client(dict(request.headers))
        github_token = dict(request.headers).get("x-github-token") or os.getenv("GITHUB_TOKEN")
        
        repo_name = f"{owner}/{repo}"
        repository = g.get_repo(repo_name)
        
        return {
            "status": "success",
            "repo_name": repository.full_name,
            "description": repository.description,
            "stars": repository.stargazers_count,
            "url": repository.html_url
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"リポジトリの取得に失敗しました: {str(e)}")

@app.get("/api/v1/github/code/{owner}/{repo}")
def get_repository_content(owner: str, repo: str, path: str = ""):
    """
    指定したリポジトリの特定のパス（ディレクトリまたはファイル）の情報を取得する
    """
    try:
        provider, api_key = get_ai_credentials(dict(request.headers))
        g = get_github_client(dict(request.headers))
        github_token = dict(request.headers).get("x-github-token") or os.getenv("GITHUB_TOKEN")
        
        repo_name = f"{owner}/{repo}"
        repository = g.get_repo(repo_name)
        
        # pathが指定されていない場合はルートディレクトリ（直下）を取得
        contents = repository.get_contents(path)
        
        # ディレクトリの場合（中身がリストで返ってくる）
        if isinstance(contents, list):
            files = []
            for content in contents:
                files.append({
                    "name": content.name,
                    "path": content.path,
                    "type": content.type # "dir" または "file"
                })
            return {
                "status": "success",
                "type": "directory",
                "path": path if path else "/",
                "contents": files
            }
        
        # 単一ファイルの場合
        else:
            # GitHub APIから取得したファイルの中身はエンコードされているため、UTF-8にデコードする
            decoded_text = contents.decoded_content.decode("utf-8")
            return {
                "status": "success",
                "type": "file",
                "name": contents.name,
                "path": contents.path,
                "content": decoded_text
            }
            
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"対象の取得に失敗しました。パスが間違っているか、権限がありません: {str(e)}")

# =============================================================================
# 罠コード生成用のモデル定義
# =============================================================================

class TrapGenerationResponse(BaseModel):
    """Geminiから確実にこの構造で返してもらうためのPydanticモデル"""
    feature_proposal: str  # 新機能の提案（何を追加するか）
    pr_title: str          # プルリクエストのタイトルとして相応しい、短くて自然な日本語のタイトル
    file_path: Optional[str] = None # 新規作成の場合のファイルパス
    perfect_code: str      # 脆弱性やバグを含まない、完璧な実装コード
    trap_code: str         # 完璧なコードをベースに、意図的な脆弱性や欠陥を仕込んだコード
    trap_explanation: str  # 【解説用】どんな罠（脆弱性）をどこに仕込んだか（ユーザーには隠す正解データ）

class FactCheckResponse(BaseModel):
    """ファクトチェック結果のPydanticモデル"""
    has_vulnerability: bool  # 罠コードに本当に脆弱性/欠陥が存在するか
    vulnerability_confirmed: str  # 確認された脆弱性の説明
    is_subtle_enough: bool  # 罠が十分に巧妙か（一目でバレないか）
    comments_reveal_answer: bool  # コードのコメントが答えを暴露していないか
    recommendation: str  # 改善が必要な場合の推奨事項

class AutoTrapPRRequest(BaseModel):
    """全自動罠PR生成リクエスト"""
    path: Optional[str] = None # ターゲットにする既存ファイルのパス。省略時はAIが新規ファイルを作成する
    language: Optional[str] = None  # プログラミング言語（省略時は拡張子から自動判定）
    branch_name: Optional[str] = None  # 作成するブランチ名（省略時は自動生成）
    creator_username: str  # PRを作成したユーザーのGitHub Username

class AutoTrapPRResponse(BaseModel):
    """フロントエンドや記録用に返すレスポンス"""
    status: str
    message: str
    pr_url: str         # 生成されたGitHub PRのURL
    feature_proposal: str # AIが提案した新機能の内容
    perfect_code: str   # 完璧なコード（正解コードとして後で使うため）
    trap_code: str      # 実際に仕込まれた罠コード
    trap_explanation: str # 罠の解説（裏側のデータベース記録用）
    detected_language: str # 自動検出された言語
    fact_check_passed: bool # ファクトチェック結果

class AskAIRequest(BaseModel):
    owner: str
    repo: str
    pr_number: int
    question: str

class AskAIResponse(BaseModel):
    answer: str

def _fact_check_trap_code(provider: str, api_key: str, trap_code: str, trap_explanation: str, language: str) -> dict:
    """
    【ファクトチェック】生成された罠コードが本当に脆弱性を含むか、
    コメントで答えを暴露していないかをAIで検証する
    """
    system_instruction = (
        "あなたはセキュリティ監査の専門家です。\n"
        "与えられたコードを分析し、以下を判定してください：\n"
        "1. 指摘された脆弱性/欠陥が本当にコード内に存在するか\n"
        "2. その脆弱性は一見気づきにくい巧妙なものか（コードレビューで見落とされるレベルか）\n"
        "3. コード内のコメントが脆弱性のヒントや答えを暴露していないか\n"
        "出力は必ず指定されたJSONスキーマに従ってください。"
    )

    user_prompt = f"""
    【言語】{language}
    
    【罠コード】
    ```
    {trap_code}
    ```
    
    【仕込んだとされる罠の解説】
    {trap_explanation}
    """

    response_obj = generate_structured_response(
        provider=provider,
        api_key=api_key,
        system_instruction=system_instruction,
        user_prompt=user_prompt,
        response_schema=FactCheckResponse,
        temperature=0.1
    )
    return response_obj.model_dump()


@app.post("/api/v1/agent/auto-trap-pr/{owner}/{repo}", response_model=AutoTrapPRResponse)
def auto_trap_pr(owner: str, repo: str, req: AutoTrapPRRequest, request: Request):
    """
    【コア機能】GitHubからコードを自動取得し、Geminiで罠を生成させ、自動でPRを作成する
    言語自動判定・ファクトチェック・自動コメント監視機能付き
    """
    try:
        # ----------------------------------------------------
        # STEP 1: GitHubから既存のターゲットコードを取得（パス指定時）
        # ----------------------------------------------------
        provider, api_key = get_ai_credentials(dict(request.headers))
        g = get_github_client(dict(request.headers))
        github_token = dict(request.headers).get("x-github-token") or os.getenv("GITHUB_TOKEN")
        
        repo_name = f"{owner}/{repo}"
        repository = g.get_repo(repo_name)
        
        is_new_file = False
        target_code = ""
        target_file_name = ""
        contents = None
        
        if req.path:
            contents = repository.get_contents(req.path)
            if isinstance(contents, list):
                raise HTTPException(status_code=400, detail="指定されたパスはディレクトリです。ファイルを指定してください。")
            target_code = contents.decoded_content.decode("utf-8")
            target_file_name = contents.name
        else:
            is_new_file = True

        project_context = ""
        if is_new_file:
            try:
                root_contents = repository.get_contents("")
                context_texts = []
                count = 0
                for content in root_contents:
                    if count >= 3:
                        break
                    if content.type == "file":
                        _, ext = os.path.splitext(content.name)
                        if ext.lower() in [".py", ".js", ".ts", ".jsx", ".tsx", ".java", ".go", ".rb", ".php", ".cs", ".cpp", ".dart", ".rs", ".swift"]:
                            try:
                                decoded = content.decoded_content.decode("utf-8")
                                lines = decoded.splitlines()[:50]
                                context_texts.append(f"--- {content.path} ---\n" + "\n".join(lines))
                                count += 1
                            except:
                                pass
                if context_texts:
                    project_context = "【プロジェクトの既存コード（一部参考）】\n" + "\n".join(context_texts)
            except Exception as e:
                print(f"Failed to fetch context: {e}")

        # ----------------------------------------------------
        # STEP 1.5: 言語自動判定
        # ----------------------------------------------------
        if req.language:
            detected_language = req.language
        elif req.path:
            detected_language = detect_language(req.path)
            if detected_language == "unknown":
                detected_language = "unknown (auto-detect failed, treating as generic code)"
        else:
            detected_language = "任意 (AIが決定)"

        # ----------------------------------------------------
        # STEP 2: Gemini APIを呼び出して、罠コードを生成
        # ----------------------------------------------------
        if is_new_file:
            system_instruction = (
                "あなたは悪意ある開発者を演じるAIエージェントであり、同時に優秀なプログラミング講師です。\n"
                "プロジェクトがより便利になる『新機能』を1つ提案し、そのための新しいファイルを作成してください。\n"
                "以下の項目を生成してください。\n"
                "1. 追加する新機能の提案（何を追加するか）\n"
                "2. プルリクエストのタイトル（pr_title: 短くて自然な日本語のタイトル）\n"
                "3. 新規作成するファイルのパス（例: src/auth.js, utils/api.py など。file_pathに指定してください）\n"
                "4. 脆弱性やバグを含まない、完璧な実装コード\n"
                "5. その完璧なコードをベースに、構造的な欠陥やセキュリティ上の罠（脆弱性）を巧妙に仕込んだ『罠コード』\n"
                "罠コードは、一見すると正常に動くように見え、コードレビューをすり抜けるような巧妙なものにしてください。\n"
                "\n"
                "【絶対に守るべきルール】\n"
                "- trap_code 内に罠の内容を示すコメントを一切書かないでください。\n"
                "- 「ここが脆弱性です」「意図的にXXしています」のようなコメントは厳禁です。\n"
                "- コメントは通常の開発者が書くような自然なものだけにしてください。\n"
                "- trap_explanation にのみ罠の詳細を記述してください。\n"
                "出力は必ず指定されたJSONスキーマに従ってください。"
            )
            user_prompt = "新しい機能のためのファイルと罠コードを生成してください。\n"
            if project_context:
                user_prompt += f"\n以下の既存コードのコーディングスタイルやプロジェクト構造を参考に、関連性のある自然な新機能を考案してください。\n{project_context}"
        else:
            system_instruction = (
                "あなたは悪意ある開発者を演じるAIエージェントであり、同時に優秀なプログラミング講師です。\n"
                "提出された既存のソースコードを読み込み、プロジェクトがより便利になる『新機能』を1つ提案してください。\n"
                "そして、その新機能を実現するための『問題を含まない完璧なコード』を作成してください。\n"
                "最後に、その完璧なコードをベースに、構造的な欠陥やセキュリティ上の罠（脆弱性）を巧妙に仕込んだ『罠コード』を生成してください。\n"
                "罠コードは、一見すると正常に動くように見え、コードレビューをすり抜けるような巧妙なものにしてください。\n"
                "また、プルリクエストのタイトルとして相応しい、短くて自然な日本語のタイトル（pr_title）も考えてください。\n"
                "\n"
                "【絶対に守るべきルール】\n"
                "- trap_code 内に罠の内容を示すコメントを一切書かないでください。\n"
                "- 「ここが脆弱性です」「意図的にXXしています」のようなコメントは厳禁です。\n"
                "- コメントは通常の開発者が書くような自然なものだけにしてください。\n"
                "- trap_explanation にのみ罠の詳細を記述してください。\n"
                "出力は必ず指定されたJSONスキーマに従ってください。"
            )
            user_prompt = f"対象ファイル名: {target_file_name}\n言語: {detected_language}\n\n【既存のソースコード】\n```\n{target_code}\n```"

        # AIプロバイダを使用して構造化出力を得る
        response_obj = generate_structured_response(
            provider=provider,
            api_key=api_key,
            system_instruction=system_instruction,
            user_prompt=user_prompt,
            response_schema=TrapGenerationResponse,
            temperature=0.7
        )
        ai_data = response_obj.model_dump()

        # ----------------------------------------------------
        # STEP 2.5: ファクトチェック - 罠コードが本当に脆弱性を含むか検証
        # ----------------------------------------------------
        fact_check_passed = False
        max_retries = 2
        
        for attempt in range(max_retries + 1):
            fact_check = _fact_check_trap_code(provider, api_key, ai_data["trap_code"], ai_data["trap_explanation"], detected_language)
            
            if fact_check["has_vulnerability"] and not fact_check["comments_reveal_answer"]:
                fact_check_passed = True
                break
            
            if attempt < max_retries:
                # ファクトチェック失敗時: 罠コードを再生成
                retry_instruction = system_instruction + (
                    f"\n\n【前回の生成で問題がありました】\n"
                    f"問題点: {fact_check['recommendation']}\n"
                    f"コメントが答えを暴露していないか: {fact_check['comments_reveal_answer']}\n"
                    f"脆弱性が実際に存在するか: {fact_check['has_vulnerability']}\n"
                    f"上記の問題を修正して再生成してください。"
                )
                response_obj = generate_structured_response(
                    provider=provider,
                    api_key=api_key,
                    system_instruction=retry_instruction,
                    user_prompt=user_prompt,
                    response_schema=TrapGenerationResponse,
                    temperature=0.7
                )
                ai_data = response_obj.model_dump()

        # ----------------------------------------------------
        # STEP 3: 新しいブランチを作成し、罠コードで上書きしてPRを作成
        # ----------------------------------------------------
        default_branch = repository.default_branch
        base_ref = repository.get_branch(default_branch)
        
        # ブランチ名を自動生成（タイムスタンプで一意にする）
        if req.branch_name:
            branch_name = req.branch_name
        else:
            timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
            branch_name = f"trap-challenge-{timestamp}"
        
        repository.create_git_ref(ref=f"refs/heads/{branch_name}", sha=base_ref.commit.sha)
        
        # 罠コードをコミット
        if is_new_file:
            ai_file_path = ai_data.get("file_path") or "src/new_feature.py"
            repository.create_file(
                path=ai_file_path,
                message=f"Feat: Add proposed feature",
                content=ai_data["trap_code"],
                branch=branch_name
            )
        else:
            repository.update_file(
                path=req.path,
                message=f"Feat: Add proposed feature for {target_file_name}",
                content=ai_data["trap_code"],
                sha=contents.sha, # 上書きには既存ファイルのSHAが必要
                branch=branch_name
            )
        
        # GitHub上でPRを作成（答えを含めない）
        pr_title = ai_data.get("pr_title", f"[Trap Challenge] {ai_data['feature_proposal'][:60]}")
        # 安全のためにプレフィックスを強制
        if not pr_title.startswith("[Trap Challenge]"):
            pr_title = f"[Trap Challenge] {pr_title}"
            
        pr_body = (
            f"### 🚀 AIエージェントからの新機能提案\n"
            f"{ai_data['feature_proposal']}\n\n"
            f"--- \n"
            f"💡 **レビューアーへの挑戦**:\n"
            f"このPRのコードには、巧妙なバグやセキュリティ上の脆弱性（罠）が仕込まれています。\n"
            f"コードを注意深くレビューし、問題点を見つけてコメントで指摘してください！\n\n"
            f"⏰ コメントを投稿すると自動で採点されます。"
        )
        
        pr = repository.create_pull(
            title=pr_title,
            body=pr_body,
            head=branch_name,
            base=default_branch
        )

        # ----------------------------------------------------
        # STEP 4: Firestoreに罠PRの情報を記録
        # ----------------------------------------------------
        doc_id = f"{owner}_{repo}_{pr.number}"
        
        trap_data = {
            "owner": owner,
            "repo": repo,
            "creator_username": req.creator_username,
            "pr_number": pr.number,
            "pr_url": pr.html_url,
            "feature_proposal": ai_data["feature_proposal"],
            "perfect_code": ai_data["perfect_code"],
            "trap_code": ai_data["trap_code"],
            "trap_explanation": ai_data["trap_explanation"],
            "status": "pending",  # 初期状態は「挑戦中(pending)」
            "score": None,
            "feedback": None,
            "detected_language": detected_language,
            "fact_check_passed": fact_check_passed,
            "created_at": datetime.utcnow(),
            "last_checked_comment_id": 0,  # コメント監視用
        }
        
        # Firestoreの "traps" コレクションに保存
        db.collection("traps").document(doc_id).set(trap_data)

        # ----------------------------------------------------
        # STEP 5: バックグラウンドでコメント監視を開始（専用スレッド）
        # ----------------------------------------------------
        watcher_thread = threading.Thread(
            target=_poll_for_comments,
            args=(owner, repo, pr.number, github_token, provider, api_key, req.creator_username),
            daemon=True,  # メインプロセス終了時に自動停止
        )
        watcher_thread.start()
        print(f"[Watcher] Started polling thread for PR #{pr.number}")

        # 全ての処理結果をまとめて返却
        return {
            "status": "success",
            "message": f"罠PR生成完了！言語: {detected_language}, ファクトチェック: {'合格' if fact_check_passed else '要確認'}",
            "pr_url": pr.html_url,
            "feature_proposal": ai_data["feature_proposal"],
            "perfect_code": ai_data["perfect_code"],
            "trap_code": ai_data["trap_code"],
            "trap_explanation": ai_data["trap_explanation"],
            "detected_language": detected_language,
            "fact_check_passed": fact_check_passed,
        }
            
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"全自動PR生成に失敗しました: {str(e)}")

@app.get("/api/v1/github/user/{username}")
def get_github_user_info(username: str, request: Request):
    """GitHubのユーザー情報（アバターアイコンなど）を取得する"""
    g = get_github_client(dict(request.headers))
    try:
        user = g.get_user(username)
        return {
            "username": user.login,
            "name": user.name,
            "avatar_url": user.avatar_url,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"ユーザー情報の取得に失敗しました: {str(e)}")

@app.get("/api/v1/github/repos/{owner}")
def get_github_repos(owner: str, request: Request):
    g = get_github_client(dict(request.headers))
    try:
        user = g.get_user(owner)
        repos = user.get_repos(sort="updated", direction="desc")
        repo_names = [repo.name for repo in repos[:100]]
        return {"repos": repo_names}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch repos: {str(e)}")

@app.get("/api/v1/github/repos/{owner}/{repo}/files")
def get_github_repo_files(owner: str, repo: str, request: Request):
    g = get_github_client(dict(request.headers))
    try:
        gh_repo = g.get_repo(f"{owner}/{repo}")
        branch = gh_repo.default_branch
        tree = gh_repo.get_git_tree(branch, recursive=True)
        excluded_exts = {".png", ".jpg", ".jpeg", ".gif", ".ico", ".svg", ".pdf", ".mp4", ".zip", ".tar", ".gz", ".pyc", ".class"}
        files = []
        for element in tree.tree:
            if element.type == "blob":
                _, ext = os.path.splitext(element.path)
                if ext.lower() not in excluded_exts:
                    files.append(element.path)
        return {"files": files[:1000]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch files: {str(e)}")

# =============================================================================
# Agent API (PR生成、採点)
# =============================================================================

class ReviewScoreResponse(BaseModel):
    """Geminiからの採点結果を構造化するためのモデル"""
    is_correct: bool       # 罠を正しく指摘できているか（合格ラインに達しているか）
    score: int             # 採点スコア (0から100の間)
    feedback: str          # ユーザーへのフィードバック・解説メッセージ

def _execute_scoring(owner: str, repo: str, pr_number: int, github_token: str = None, ai_provider: str = "gemini", ai_api_key: str = None) -> dict:
    """
    採点処理の本体。Webhook・ポーリング・手動ボタンすべてから呼ばれる共通ロジック。
    """
    # STEP 0: FirestoreからこのPRの罠データ（正解）を取得
    doc_id = f"{owner}_{repo}_{pr_number}"
    doc_ref = db.collection("traps").document(doc_id)
    doc = doc_ref.get()
    
    if not doc.exists:
        raise HTTPException(status_code=404, detail="指定されたPRの罠記録がデータベースにありません。")
        
    trap_db_data = doc.to_dict()
    
    # すでに採点済みの場合はスキップ
    if trap_db_data.get("status") in ("solved", "failed"):
        return {
            "is_correct": trap_db_data.get("status") == "solved",
            "score": trap_db_data.get("score", 0),
            "feedback": trap_db_data.get("feedback", ""),
            "message": "この問題はすでに採点済みです。"
        }
    
    trap_explanation = trap_db_data["trap_explanation"]
    
    # STEP 1: GitHubからPRのコメントを取得
    g = Github(auth=Auth.Token(github_token)) if github_token else get_github_client({})
    repo_name = f"{owner}/{repo}"
    repository = g.get_repo(repo_name)
    pull_request = repository.get_pull(pr_number)
    
    # PRに紐づくすべてのコメント（通常のコメントと、コード上のレビューコメント）を回収
    # ただし自動採点結果のコメントは除外する
    comments = []
    
    try:
        bot_user = g.get_user().login
    except:
        bot_user = None

    # 通常のPRコメントを取得
    for comment in pull_request.get_issue_comments():
        if not comment.body.startswith("## 🤖 Trap-PR Agent"):
            comments.append(f"{comment.user.login}: {comment.body}")
        
    # コード行に対するレビューコメントを取得
    for comment in pull_request.get_comments():
        if not comment.body.startswith("## 🤖 Trap-PR Agent"):
            comments.append(f"{comment.user.login} (on code): {comment.body}")
        
    if not comments:
        return None  # コメントがまだない場合はNone
        
    # コメント履歴を1つのテキストにまとめる
    user_reviews_text = "\n---\n".join(comments)

    # STEP 2: Geminiにコメントを渡して採点させる
    system_instruction = (
        "あなたは厳格でありながらも育成熱心なプログラミング講師です。\n"
        "ユーザー（開発者）がコードレビューとして残したコメントを読み、彼らが『仕込まれた罠（脆弱性や欠陥）』を正しく見抜けきれているかを評価してください。\n"
        "単に『バグがある』という指摘だけでなく、具体的にどの部分がどう危険か（例: ゼロ除算、SQLインジェクション、バックドア等）を言い当てているかを重視してください。\n"
        "出力は必ず指定されたJSONスキーマ（is_correct, score, feedback）に従ってください。\n"
        "【必須事項】\n"
        "feedback内には、「どこに（ファイル名や該当箇所）」「どのようなミス（脆弱性やバグの内容）があったか」を明確に記載してください。\n"
        "また、ユーザーの指摘の良い点、足りない点をレビューし、最後に正解（罠の解説）を優しく教えてあげてください。"
    )

    user_prompt = f"""
    【仕込まれていた罠の解説（正解データ）】
    {trap_explanation}
    
    【ユーザーが残したレビューコメント一覧】
    {user_reviews_text}
    """

    # フォールバック処理
    if not ai_api_key:
        ai_provider, ai_api_key = get_ai_credentials({})

    response_obj = generate_structured_response(
        provider=ai_provider,
        api_key=ai_api_key,
        system_instruction=system_instruction,
        user_prompt=user_prompt,
        response_schema=ReviewScoreResponse,
        temperature=0.2
    )
    score_data = response_obj.model_dump()

    # STEP 3: 採点結果をGitHubのPRに自動コメント投稿する
    result_emoji = "🎉 【合格】" if score_data["is_correct"] else "❌ 【不合格/未達成】"
    
    github_comment_body = (
        f"## 🤖 Trap-PR Agent 採点結果\n"
        f"**判定:** {result_emoji}\n"
        f"**スコア:** `{score_data['score']} / 100` 点\n\n"
        f"### 💡 エージェントからのフィードバック\n"
        f"{score_data['feedback']}\n\n"
        f"--- \n"
        f"修業を続けて、さらなる罠を見破れるようになりましょう！"
    )
    
    # PRに結果を書き込む
    pull_request.create_issue_comment(github_comment_body)

    # STEP 4: 採点結果をFirestoreにアップデート記録
    doc_ref.update({
        "status": "solved" if score_data["is_correct"] else "failed",
        "score": score_data["score"],
        "feedback": score_data["feedback"],
        "updated_at": datetime.utcnow()
    })

    return {
        "is_correct": score_data["is_correct"],
        "score": score_data["score"],
        "feedback": score_data["feedback"],
        "message": "GitHubへの採点コメントの投稿が完了しました！"
    }


@app.post("/api/v1/agent/score-review/{owner}/{repo}/{pr_number}")
def score_review(owner: str, repo: str, pr_number: int, request: Request):
    """
    指定されたPRのコメントを取得し、仕込まれた罠を指摘できているかをGeminiに採点させ、結果をPRにコメントする
    """
    try:
        result = _execute_scoring(owner, repo, pr_number)
        if result is None:
            raise HTTPException(status_code=400, detail="PRにまだコメントが投稿されていません。レビューコメントを書き込んでから再度実行してください。")
        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"採点処理に失敗しました: {str(e)}")


# =============================================================================
# コメント自動監視（ポーリング）
# =============================================================================

def _poll_for_comments(owner: str, repo: str, pr_number: int, github_token: str, provider: str, api_key: str, creator_username: str, interval: int = 10, max_polls: int = 120):
    """
    バックグラウンドスレッドでPRのコメントをポーリングし、新規コメントを検知したら自動で採点する。
    interval秒ごとにチェックし、最大max_polls回（デフォルト1時間）で停止。
    threading.Threadで実行されるため、time.sleep()がメインスレッドをブロックしない。
    """
    import time
    
    watcher_key = f"{owner}_{repo}_{pr_number}"
    active_watchers[watcher_key] = True
    print(f"[Watcher] Polling started for {watcher_key} (interval={interval}s, max={max_polls})")
    
    for poll_count in range(max_polls):
        if not active_watchers.get(watcher_key, False):
            print(f"[Watcher] {watcher_key} - stopped by flag")
            break
            
        time.sleep(interval)
        
        try:
            # Firestoreからステータスを確認
            doc_id = f"{owner}_{repo}_{pr_number}"
            doc_ref = db.collection("traps").document(doc_id)
            doc = doc_ref.get()
            
            if not doc.exists:
                print(f"[Watcher] {watcher_key} - document not found, stopping")
                break
                
            trap_data = doc.to_dict()
            
            # すでに採点済みなら監視終了
            if trap_data.get("status") in ("solved", "failed"):
                print(f"[Watcher] {watcher_key} - already scored, stopping")
                break
            
            # コメントがあるか確認
            g = Github(auth=Auth.Token(github_token)) if github_token else get_github_client({})
            repo_name = f"{owner}/{repo}"
            repository = g.get_repo(repo_name)
            pull_request = repository.get_pull(pr_number)
            
            # 通常コメント + コードレビューコメント（自動採点結果は除外、creator_username以外のコメントは除外）
            has_new_comments = False
            for comment in pull_request.get_issue_comments():
                if not comment.body.startswith("## 🤖 Trap-PR Agent"):
                    if comment.user.login == creator_username:
                        has_new_comments = True
                        break
            
            if not has_new_comments:
                for comment in pull_request.get_comments():
                    if not comment.body.startswith("## 🤖 Trap-PR Agent"):
                        if comment.user.login == creator_username:
                            has_new_comments = True
                            break
            
            if has_new_comments:
                # コメントが見つかったら採点実行
                print(f"[Watcher] {watcher_key} - comment detected! Starting scoring...")
                result = _execute_scoring(owner, repo, pr_number)
                print(f"[Watcher] {watcher_key} - scoring complete: {result}")
                break  # 採点完了したら監視終了
            else:
                print(f"[Watcher] {watcher_key} - poll #{poll_count+1}, no comments yet")
                
        except Exception as e:
            print(f"[Watcher] Error polling {watcher_key}: {e}")
            continue
    
    # 監視終了
    active_watchers.pop(watcher_key, None)
    print(f"[Watcher] {watcher_key} - polling ended")
    return {"status": "scoring_completed"}


@app.post("/api/v1/agent/ask-ai", response_model=AskAIResponse)
def ask_ai(req: AskAIRequest, request: Request):
    """
    指定されたPRのコンテキスト（コードと罠の解説）をもとにAIに質問する
    """
    try:
        provider, api_key = get_ai_credentials(dict(request.headers))
        
        # FirestoreからPRのコンテキストを取得
        doc_id = f"{req.owner}_{req.repo}_{req.pr_number}"
        doc = db.collection("traps").document(doc_id).get()
        
        if not doc.exists:
            raise HTTPException(status_code=404, detail="PR情報が見つかりません。")
        
        trap_data = doc.to_dict()
        
        system_instruction = (
            "あなたはTrap-PR AgentのアシスタントAIです。\n"
            "ユーザーは現在、以下のコードレビュー問題に挑戦中です。\n"
            "ユーザーからの質問に対して、適切な回答を提示してください。\n\n"
            "【絶対に守るべきルール】\n"
            "- 罠の「直接的な答え」を絶対に教えないでください。\n"
            "- ユーザーが自分で罠を見つけられるように、ヒントや考え方のガイダンスを提供してください。\n"
            "- コードの動作や一般的なセキュリティのベストプラクティスについては回答して構いません。\n"
            "- ユーザーの回答が間違っている場合、「それは間違いです。なぜなら...」と優しく訂正してください。"
        )
        
        user_prompt = f"""
        【現在の状況】
        罠コード:
        ```
        {trap_data.get('trap_code', '')}
        ```
        
        【正解（裏の文脈であり、ユーザーには直接教えないこと）】
        {trap_data.get('trap_explanation', '')}
        
        【ユーザーからの質問】
        {req.question}
        """
        
        from ai_service import _get_ai_client
        client = _get_ai_client(provider, api_key)
        
        # Instructor等による構造化は不要なので、通常のテキスト生成を行う
        # 簡易的に同じ関数を使って { "answer": "..." } スキーマで返させる
        response_obj = generate_structured_response(
            provider=provider,
            api_key=api_key,
            system_instruction=system_instruction,
            user_prompt=user_prompt,
            response_schema=AskAIResponse,
            temperature=0.7
        )
        return response_obj.model_dump()
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AIへの質問に失敗しました: {str(e)}")


@app.post("/api/v1/agent/start-watcher/{owner}/{repo}/{pr_number}")
def start_watcher(owner: str, repo: str, pr_number: int):
    """
    指定されたPRのコメント監視を手動で開始する
    """
    watcher_key = f"{owner}_{repo}_{pr_number}"
    
    if active_watchers.get(watcher_key, False):
        return {"status": "already_running", "message": "このPRの監視はすでに実行中です。"}
    
    watcher_thread = threading.Thread(
        target=_poll_for_comments,
        args=(owner, repo, pr_number),
        daemon=True,
    )
    watcher_thread.start()
    
    return {"status": "started", "message": f"PR #{pr_number} のコメント監視を開始しました。コメントが検知されると自動で採点されます。"}


# =============================================================================
# GitHub Webhook エンドポイント（本番Cloud Run用）
# =============================================================================

@app.post("/api/v1/webhook/github")
async def github_webhook(request: Request, background_tasks: BackgroundTasks):
    """
    GitHubからのWebhookイベントを受け取り、PRコメントイベント時に自動採点を実行する。
    Cloud Run上でGitHub Webhook URLとしてこのエンドポイントを登録してください。
    """
    event_type = request.headers.get("X-GitHub-Event", "")
    
    if event_type not in ("issue_comment", "pull_request_review_comment", "pull_request_review"):
        return {"status": "ignored", "event": event_type}
    
    payload = await request.json()
    
    # コメント作成イベントのみ処理
    action = payload.get("action", "")
    if action != "created":
        return {"status": "ignored", "action": action}
    
    # PR情報の取得
    pr_number = None
    owner = None
    repo = None
    
    if event_type == "issue_comment":
        # issue_comment イベントの場合、PRかどうかを確認
        issue = payload.get("issue", {})
        if "pull_request" not in issue:
            return {"status": "ignored", "reason": "not_a_pull_request"}
        pr_number = issue.get("number")
    elif event_type in ("pull_request_review_comment", "pull_request_review"):
        pr = payload.get("pull_request", {})
        pr_number = pr.get("number")
    
    repo_info = payload.get("repository", {})
    full_name = repo_info.get("full_name", "")
    if "/" in full_name:
        owner, repo = full_name.split("/", 1)
    
    if not all([pr_number, owner, repo]):
        return {"status": "error", "detail": "PR情報を取得できませんでした。"}
    
    # 自動採点結果のコメントは無視
    comment_body = payload.get("comment", {}).get("body", "")
    if comment_body.startswith("## 🤖 Trap-PR Agent"):
        return {"status": "ignored", "reason": "bot_comment"}
    
    # Firestoreで罠PRかどうかを確認
    doc_id = f"{owner}_{repo}_{pr_number}"
    doc = db.collection("traps").document(doc_id).get()
    
    if not doc.exists:
        return {"status": "ignored", "reason": "not_a_trap_pr"}
    
    trap_data = doc.to_dict()
    if trap_data.get("status") in ("solved", "failed"):
        return {"status": "ignored", "reason": "already_scored"}
        
    creator_username = trap_data.get("creator_username")
    comment_user = payload.get("comment", {}).get("user", {}).get("login", "")
    if creator_username and comment_user != creator_username:
        return {"status": "ignored", "reason": "comment_not_by_creator"}
    
    # バックグラウンドで採点を実行
    background_tasks.add_task(_execute_scoring, owner, repo, pr_number)
    
    return {"status": "scoring_started", "pr_number": pr_number}


# =============================================================================
# 統計情報
# =============================================================================

@app.get("/api/v1/records/stats/{creator_username}")
def get_user_stats(creator_username: str):
    """
    指定されたユーザー（作成者）の累計罠PR数、解決数、Accuracy（正解率）、累計スコアを計算して返す
    """
    try:
        # 指定したcreator_usernameの罠データを全件取得
        docs = db.collection("traps").where("creator_username", "==", creator_username).stream()
        
        total_prs = 0
        solved_count = 0
        failed_count = 0
        pending_count = 0
        total_score = 0
        history = []
        
        for doc in docs:
            data = doc.to_dict()
            total_prs += 1
            
            status = data.get("status", "pending")
            if status == "solved":
                solved_count += 1
            elif status == "failed":
                failed_count += 1
            else:
                pending_count += 1
                
            if data.get("score"):
                total_score += data["score"]
                
            # 履歴一覧用のコンパクトなデータ構造
            history.append({
                "pr_number": data["pr_number"],
                "repo": data["repo"],
                "pr_url": data["pr_url"],
                "feature_proposal": data["feature_proposal"],
                "status": status,
                "score": data.get("score"),
                "created_at": data["created_at"].isoformat() if data.get("created_at") else None
            })
            
        # Accuracy（正解率）の計算。分母は結果が出ているもの（solved + failed）
        reviewed_total = solved_count + failed_count
        accuracy = (solved_count / reviewed_total * 100) if reviewed_total > 0 else 0.0
        
        return {
            "owner": creator_username,
            "total_generated_prs": total_prs,  # 累計生成PR数
            "solved_count": solved_count,       # 解決数
            "failed_count": failed_count,       # 不合格数
            "pending_count": pending_count,     # 挑戦中数
            "accuracy": round(accuracy, 2),     # 累計Accuracy (%)
            "total_score": total_score,         # 累計スコア
            "history": sorted(history, key=lambda x: x["pr_number"], reverse=True) # 新しい順
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"統計データの取得に失敗しました: {str(e)}")