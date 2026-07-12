import os
import json
import instructor
from pydantic import BaseModel
from typing import Type, TypeVar, Any

# Gemini
from google import genai
from google.genai import types as genai_types
# OpenAI
from openai import OpenAI
# Anthropic
from anthropic import Anthropic

T = TypeVar('T', bound=BaseModel)

def generate_structured_response(
    provider: str,
    api_key: str,
    system_instruction: str,
    user_prompt: str,
    response_schema: Type[T],
    temperature: float = 0.7
) -> T:
    """
    指定されたAIプロバイダとAPIキーを使って、Pydanticモデル(response_schema)に従った構造化データを出力する。
    """
    provider = provider.lower().strip()
    
    if provider == "gemini":
        client = genai.Client(api_key=api_key)
        response = client.models.generate_content(
            model='gemini-1.5-flash',
            contents=user_prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                response_schema=response_schema,
                temperature=temperature,
                thinking_config=genai_types.ThinkingConfig(thinking_budget=0),
            ),
        )
        return response_schema.model_validate_json(response.text)
        
    elif provider == "vertexai":
        location = os.getenv("GCP_LOCATION", "us-central1")
        client = genai.Client(vertexai=True, location=location)
        response = client.models.generate_content(
            model='gemini-1.5-flash-001',
            contents=user_prompt,
            config=genai_types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                response_schema=response_schema,
                temperature=temperature,
                thinking_config=genai_types.ThinkingConfig(thinking_budget=0),
            ),
        )
        return response_schema.model_validate_json(response.text)
        
    elif provider == "openai":
        client = instructor.from_openai(OpenAI(api_key=api_key))
        response = client.chat.completions.create(
            model="gpt-4o",
            response_model=response_schema,
            temperature=temperature,
            messages=[
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": user_prompt},
            ],
        )
        return response
        
    elif provider == "anthropic":
        client = instructor.from_anthropic(Anthropic(api_key=api_key))
        response = client.messages.create(
            model="claude-3-5-sonnet-latest",
            max_tokens=4096,
            response_model=response_schema,
            temperature=temperature,
            system=system_instruction,
            messages=[
                {"role": "user", "content": user_prompt},
            ],
        )
        return response
        
    else:
        raise ValueError(f"Unknown AI Provider: {provider}")

from fastapi import HTTPException

def get_ai_credentials(request_headers: dict) -> tuple[str, str]:
    """
    リクエストヘッダーからプロバイダとAPIキーを取得する。
    無い場合は環境変数 (.env) にフォールバックする。
    """
    provider = request_headers.get("x-ai-provider", "gemini").lower()
    api_key = request_headers.get("x-ai-api-key")
    
    if provider == "vertexai":
        # Vertex AI uses Google Cloud ADC, no explicit API key required from frontend
        return provider, api_key or ""

    if not api_key:
        if provider == "gemini":
            import random
            gemini_keys = [v for k, v in os.environ.items() if k.startswith("GEMINI_API") and v.strip()]
            if gemini_keys:
                api_key = random.choice(gemini_keys)
        elif provider == "openai":
            api_key = os.getenv("OPENAI_API_KEY")
        elif provider == "anthropic":
            api_key = os.getenv("ANTHROPIC_API_KEY")
            
    if not api_key:
        raise HTTPException(status_code=400, detail=f"API Key for {provider} is missing. アプリの設定画面から入力するか、サーバーの.envファイルを確認してください。")
        
    return provider, api_key
