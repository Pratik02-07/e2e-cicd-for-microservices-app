import importlib.util
import os

import pytest

SERVICES_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_app(service_name):
    """Load a service's Flask app from its app.py without needing a package."""
    app_path = os.path.join(SERVICES_DIR, service_name, "app.py")
    spec = importlib.util.spec_from_file_location(f"{service_name}_app", app_path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.app


@pytest.mark.parametrize("service", ["frontend", "product-service", "cart-service"])
def test_health_endpoint(service):
    app = load_app(service)
    client = app.test_client()
    response = client.get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "healthy"


def test_products_endpoint():
    app = load_app("product-service")
    client = app.test_client()
    response = client.get("/products")
    assert response.status_code == 200
    body = response.get_json()
    assert body["count"] >= 1
    assert len(body["products"]) == body["count"]


def test_cart_endpoint():
    app = load_app("cart-service")
    client = app.test_client()
    response = client.get("/cart")
    assert response.status_code == 200
    assert "items" in response.get_json()


def test_product_not_found():
    app = load_app("product-service")
    client = app.test_client()
    response = client.get("/products/9999")
    assert response.status_code == 404
