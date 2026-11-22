from flask import Flask, jsonify

app = Flask(__name__)

CART = {"items": [], "total": 0.0}


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "cart-service"}), 200


@app.route("/cart", methods=["GET"])
def get_cart():
    return jsonify(CART), 200


@app.route("/cart/add/<item_name>", methods=["POST"])
def add_item(item_name):
    CART["items"].append(item_name)
    CART["total"] += 10.0
    return jsonify({"message": f"{item_name} added", "cart": CART}), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=False)
