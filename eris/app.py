from models import engine
from models import Incident
from models import User
from models import Comment

from sqlalchemy.orm import Session

from flask import Flask, render_template

app = Flask(__name__)


@app.route("/")
def root():
    """ Returns the index page. """
    return render_template("index.html", incidents=incidents)


@app.route("/incidents")
def list_incidents():
    """ Returns all the incidents"""
    with Session(engine) as conn:
        conn.get(Incident)
