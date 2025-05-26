#!/usr/bin/env python3
import subprocess
import os
import argparse
import sys
import anthropic

def get_git_diff(staged_only=True):
    """Get the git diff for either staged files or all changes."""
    try:
        if staged_only:
            # Get diff for staged files only
            diff = subprocess.check_output(["git", "diff", "--staged"], text=True)
            if not diff.strip():
                print("No staged changes found. Use --all to include unstaged changes.")
                return None
        else:
            # Get diff for all changes
            diff = subprocess.check_output(["git", "diff"], text=True)
            if not diff.strip():
                print("No changes found in the repository.")
                return None
        return diff
    except subprocess.CalledProcessError as e:
        print(f"Error getting git diff: {e}")
        return None
    except FileNotFoundError:
        print("Git command not found. Make sure git is installed.")
        return None

def generate_commit_message(diff, model="claude-3-7-sonnet-20250219"):
    """Generate a commit message using Anthropic API."""
    # Check if API key is set
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set.")
        print("Set it with: export ANTHROPIC_API_KEY=your_api_key")
        return None
    
    client = anthropic.Anthropic()
    
    # Truncate diff if it's too large
    max_diff_length = 10000  # Characters
    if len(diff) > max_diff_length:
        diff = diff[:max_diff_length] + f"\n\n[Diff truncated. Total length: {len(diff)} characters]"
    
    prompt = f"""
    Please analyze the following git diff and write a concise, informative commit message:

    ```
    {diff}
    ```
    
    Create a commit message that:
    1. Has a brief one-line summary (max 50 chars)
    2. Uses the imperative mood (e.g., "Add" not "Added")
    3. Includes an optional longer description after a blank line, if needed
    4. Covers the main changes without unnecessary detail
    
    Return ONLY the commit message with no additional explanation or formatting.
    """

    try:
        response = client.messages.create(
            model=model,
            max_tokens=200,
            messages=[{"role": "user", "content": prompt}]
        )
        return response.content[0].text.strip()
    except Exception as e:
        print(f"Error generating commit message: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Generate a commit message based on git diff")
    parser.add_argument("--all", action="store_true", help="Include unstaged changes in the analysis")
    parser.add_argument("--model", default="claude-3-haiku-20240307", 
                        help="Anthropic model to use (default: claude-3-haiku-20240307)")
    args = parser.parse_args()
    
    # Check if current directory is a git repository
    if not os.path.isdir(".git"):
        print("Current directory is not a git repository.")
        return 1
    
    # Get the git diff
    diff = get_git_diff(staged_only=not args.all)
    if not diff:
        return 1
    
    # Generate commit message
    commit_message = generate_commit_message(diff, args.model)
    if not commit_message:
        return 1
    
    # Print the suggested commit message
    print("\n=== Suggested Commit Message ===")
    print(commit_message)
    print("================================\n")
    
    # Ask if user wants to use this message
    try:
        response = input("Use this commit message? (y/n): ").strip().lower()
        if response == 'y':
            # Create a temporary file with the commit message
            with open(".git/COMMIT_EDITMSG", "w") as f:
                f.write(commit_message)
            
            # Execute git commit with the message
            subprocess.run(["git", "commit", "-F", ".git/COMMIT_EDITMSG"])
            print("Changes committed successfully!")
        else:
            print("Commit message not applied. You can copy it manually if needed.")
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())