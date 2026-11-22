import os
from flask import Flask, jsonify, render_template_string

app = Flask(__name__)

PRODUCT_URL = os.getenv("PRODUCT_URL", "http://product-service:5001")
CART_URL = os.getenv("CART_URL", "http://cart-service:5002")


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "frontend"}), 200


@app.route("/", methods=["GET"])
def index():
    html = """
    <!DOCTYPE html>
    <html>
    <head><title>Microservices Store</title></head>
    <body>
      <h1>Microservices Store</h1>
      <p><a href="/products">View Products</a> | <a href="/cart">View Cart</a></p>
    </body>
    </html>
    """
    return render_template_string(html), 200


@app.route("/products", methods=["GET"])
def products():
    import urllib.request
    try:
        with urllib.request.urlopen(f"{PRODUCT_URL}/products", timeout=5) as resp:
            data = resp.read().decode()
        return data, 200, {"Content-Type": "application/json"}
    except Exception as exc:
        return jsonify({"error": f"product-service unreachable: {exc}"}), 502


@app.route("/cart", methods=["GET"])
def cart():
    import urllib.request
    try:
        with urllib.request.urlopen(f"{CART_URL}/cart", timeout=5) as resp:
            data = resp.read().decode()
        return data, 200, {"Content-Type": "application/json"}
    except Exception as exc:
        return jsonify({"error": f"cart-service unreachable: {exc}"}), 502


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80, debug=False)
