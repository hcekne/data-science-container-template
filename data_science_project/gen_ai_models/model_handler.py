from abc import ABC, abstractmethod
import logging
import logging.config
import os
import importlib
import re

class ModelHandler(ABC):
    """Abstract base class for model handlers"""
    
    def __init__(self):
        # Dynamic import to handle project renaming
        try:
            # First, try to import directly 
            from data_science_project.config.logging_config import LOGGING_CONFIG
            self.logging_config = LOGGING_CONFIG
        except ImportError:
            # If that fails, get the package name dynamically
            package_name = self.__module__.split('.')[0]
            logging_config_module = importlib.import_module(f"{package_name}.config.logging_config")
            self.logging_config = logging_config_module.LOGGING_CONFIG
            
        logging.config.dictConfig(self.logging_config)
        self.logger = logging.getLogger('model_handler')
    
    @abstractmethod
    def generate_text(self, prompt):
        """Generate text using the model"""
        pass

class OpenAIHandler(ModelHandler):
    def __init__(self, model="gpt-4o-mini"):
        super().__init__()
        from openai import OpenAI
        self.client = OpenAI(api_key=os.environ.get('OPENAI_API_KEY'))
        self.model = model
    
    def generate_text(self, prompt):
        self.logger.info(f"Sending prompt to OpenAI ({self.model})")
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a helpful AI assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        self.logger.info("Successfully generated response from OpenAI")
        return response.choices[0].message.content

class AnthropicHandler(ModelHandler):
    def __init__(self, model="claude-3-7-sonnet-20250219"):
        super().__init__()
        import anthropic
        self.client = anthropic.Anthropic(api_key=os.environ.get('ANTHROPIC_API_KEY'))
        self.model = model

    def generate_text(self, prompt):
        self.logger.info(f"Sending prompt to Anthropic ({self.model})")
        response = self.client.messages.create(
            model=self.model,
            max_tokens=1000,
            messages=[{"role": "user", "content": prompt}]
        )
        self.logger.info("Successfully generated response from Claude")
        return response.content[0].text

class GroqHandler(ModelHandler):
    def __init__(self, model="llama-3.3-70b-versatile"):
        super().__init__()
        from groq import Groq
        self.client = Groq(api_key=os.environ.get('GROQ_API_KEY'))
        self.model = model

    def clean_output(self, content: str) -> str:
        """Remove text between <think> tags and any empty lines that result."""
        # Remove text between <think> tags
        cleaned_content = re.sub(r'<think>.*?</think>', '', content, flags=re.DOTALL)
        # Remove any resulting empty lines or excessive whitespace
        cleaned_content = '\n'.join(line.strip() for line in cleaned_content.split('\n') if line.strip())
        return cleaned_content
    
    def generate_text(self, prompt):
        self.logger.info(f"Sending prompt to Groq ({self.model})")
        
        # Groq uses a similar API structure to OpenAI
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a helpful AI assistant."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.7
        )
        
        self.logger.info("Successfully generated response from Groq")
        # Clean the response before returning
        cleaned_response = self.clean_output(response.choices[0].message.content)
        return cleaned_response