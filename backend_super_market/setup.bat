@echo off
echo ========================================
echo SuperMart Manager Backend - Quick Start
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
    echo Virtual environment created!
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt

REM Check if migrations exist
if not exist "accounts\migrations\0001_initial.py" (
    echo Creating migrations...
    python manage.py makemigrations accounts
    python manage.py makemigrations products
    python manage.py makemigrations analytics
    echo.
)

REM Run migrations
echo Running migrations...
python manage.py migrate

echo.
echo ========================================
echo Setup complete!
echo ========================================
echo.
echo To start the server, run:
echo   python manage.py runserver
echo.
echo To create a superuser, run:
echo   python manage.py createsuperuser
echo.
echo API will be available at:
echo   http://localhost:8000/api/v1/
echo.
echo Admin panel:
echo   http://localhost:8000/admin/
echo.
pause
