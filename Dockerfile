FROM python:3.12

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN pip install pipenv

WORKDIR /app
COPY Pipfile Pipfile.lock .

RUN pipenv install --system --deploy

COPY docker-entrypoint.sh /docker-entrypoint.sh

COPY eris .

EXPOSE 8080

ENTRYPOINT [ /docker-entrypoint.sh ]
CMD [ "uvicorn", "--workers 2", "--port 8080", "app:app" ]