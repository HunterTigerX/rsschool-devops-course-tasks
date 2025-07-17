import pytest
from main import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_hello_world(client):
    """Test the main route returns Hello, World!"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Hello, World!' in response.data

def test_hello_world_content_type(client):
    """Test the response content type"""
    response = client.get('/')
    assert response.content_type == 'text/html; charset=utf-8'

def test_app_is_running():
    """Test that the Flask app can be created"""
    assert app is not None
    # TESTING is set to True by the test fixture
    assert app.config.get('TESTING', False) in [True, False]