from flask import Flask, jsonify

app = Flask(__name__)

PRODUCTS = [
    {"id": 1, "name": "Wireless Mouse", "price": 25.99, "stock": 100},
    {"id": 2, "name": "Mechanical Keyboard", "price": 89.50, "stock": 45},
    {"id": 3, "name": "USB-C Hub", "price": 45.00, "stock": 78},
    {"id": 4, "name": "Webcam 1080p", "price": 69.99, "stock": 32},
]


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "product-service"}), 200


@app.route("/products", methods=["GET"])
def list_products():
    return jsonify({"products": PRODUCTS, "count": len(PRODUCTS)}), 200


@app.route("/products/<int:product_id>", methods=["GET"])
def get_product(product_id):
    product = next((p for p in PRODUCTS if p["id"] == product_id), None)
    if product is None:
        return jsonify({"error": "product not found"}), 404
    return jsonify(product), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)
