import os
from fastapi import FastAPI, Request
from github import Github
from dotenv import load_dotenv

# .envファイルから環境変数を読み込む
load_dotenv()

app = FastAPI()

# GitHubの鍵をセットアップ
GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
# 鍵が正しく読み込めているか起動時にチェック
if not GITHUB_TOKEN:
    print("⚠️ GITHUB_TOKENが設定されていません！.envファイルを確認してください。")
g = Github(GITHUB_TOKEN)

@app.get("/")
def read_root():
    return {"status": "Trap-PR Agent Backend is running"}

@app.post("/webhook")
async def receive_webhook(request: Request):
    payload = await request.json()
    event = request.headers.get("X-GitHub-Event")
    
    # パターン1: コード行へのコメントが来た時
    if event == "pull_request_review_comment" and payload.get("action") == "created":
        comment_body = payload["comment"]["body"]
        user_login = payload["comment"]["user"]["login"]
        comment_id = payload["comment"]["id"] # 返信先のコメントID
        repo_full_name = payload["repository"]["full_name"] # リポジトリ名
        pr_number = payload["pull_request"]["number"] # PRの番号
        
        print(f"✅ [受信] {user_login} さん: {comment_body}")
        
        # もしBot自身（あなた）の返信なら、無限ループを防ぐためにスルーする
        # （※本来は専用のBotアカウントを作りますが、今は自分のアカウントで代用しているため）
        if "AIエージェント" in comment_body:
            return {"status": "ignored bot comment"}
            
        # -----------------------------------------------------
        # GitHubへリプライを返す処理
        # -----------------------------------------------------
        try:
            repo = g.get_repo(repo_full_name)
            pr = repo.get_pull(pr_number)
            
            # TODO: ここに後でAI(Gemini)の採点結果を入れる！
            # 今は固定のメッセージで「通信テスト」をする
            reply_message = f"@{user_login} フフフ...そこを疑うとは良い視点ですね。AIエージェントが現在採点中です...👁️"
            
            # APIを使って返信を書き込む
            pr.create_review_comment_reply(comment_id, reply_message)
            print(f"🚀 [送信成功] GitHubにリプライを返しました！")
            
        except Exception as e:
            print(f"❌ [送信エラー] {e}")

    return {"status": "success"}