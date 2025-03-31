#!/bin/bash
set -e

echo "Run database migrations"
python -c "import models;models.Base.metadata.create_all(models.engine);"

exec $@