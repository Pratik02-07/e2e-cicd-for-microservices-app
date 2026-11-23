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

@app.after_request
def add_security_headers(response):
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
    return response

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5002, debug=False)
