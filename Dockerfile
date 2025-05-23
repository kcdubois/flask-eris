FROM python:3.12

LABEL org.opencontainers.image.source = "https://github.com/kcdubois/flask-eris" 
LABEL org.opencontainers.image.description = "Simple incident management system"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN pip install pipenv

WORKDIR /app
COPY Pipfile Pipfile.lock .

RUN pipenv install --system --deploy

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

COPY eris .

EXPOSE 8000

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD [ "gunicorn --workers 2 -b 0.0.0.0:8000 app:app" ]