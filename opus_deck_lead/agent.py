import os
from anthropic import AnthropicVertex
from google import genai

client = AnthropicVertex(region="us-central1", project_id="177322380947")
message = client.messages.create(
 max_tokens=1024,
 messages=[{"role": "user", "content": "Hello! Can you help me?"}],
 model="claude-opus-5-5"
)
print(message.content[0].text)
