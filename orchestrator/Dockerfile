FROM python:3.11-slim-bookworm

WORKDIR /app

# Install uv
RUN pip install uv

# Copy project files
COPY pyproject.toml .

# Install dependencies with uv
RUN uv sync

# Copy source code
COPY app ./app
COPY tests ./tests

# Expose port
EXPOSE 8000

# Run application
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
