#! /bin/sh



python -c "import os.path; print os.path.relpath( '$2', '$1')"
