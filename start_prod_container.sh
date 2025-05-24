#!/bin/bash




docker run -p 8502:8501 \
  -e OPEN_AI_KEY=$OPEN_AI_KEY \
  -e ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY \
  -e GOOGLE_SEARCH_API_KEY=$GOOGLE_SEARCH_API_KEY \
  -e GOOGLE_SEARCH_ENGINE_ID=$GOOGLE_SEARCH_ENGINE_ID \
  data-science-prod:latest

# Print access information
echo "Production container started!"
echo "Access Jupyter Lab at: http://localhost:8888?token=easy"