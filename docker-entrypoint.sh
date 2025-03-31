#!/bin/bash
set -e

run_migrations() {
    cd eris
    python -c "import models;models.Base.metadata.create_all(models.engine);"
    cd ..
}

exec "$@"