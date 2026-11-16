<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Map" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="jdbc.jsp" %>
<!DOCTYPE html>
<html>
<head>
<title>BCML - Order Processing</title>
</head>
<body>

<% 
// Get customer id
String custId = request.getParameter("customerId");
@SuppressWarnings({"unchecked"})
HashMap<String, ArrayList<Object>> productList = (HashMap<String, ArrayList<Object>>) session.getAttribute("productList");

// Determine if valid customer id was entered
// Determine if there are products in the shopping cart
// If either are not true, display an error message

HashMap<String, Object> customer = new HashMap<>();

// Make connection
try (Connection con = getConnection()) {

	boolean invalidCart = productList == null || productList.isEmpty();
	boolean invalidCustomer = custId == null || custId.isEmpty();

	if (!invalidCart && !invalidCustomer) {
		String getCustomerSQL = """
			SELECT * 
			FROM customer
			WHERE customerId = ?
		""";
		try (PreparedStatement pstmt = con.prepareStatement(getCustomerSQL)) {
			pstmt.setInt(1, Integer.parseInt(custId));
			try (ResultSet rs = pstmt.executeQuery()) {
				if (rs.next()) {
					customer.put("customerId", rs.getInt("customerId"));
					customer.put("firstName", rs.getString("firstName"));
					customer.put("lastName", rs.getString("lastName"));
					customer.put("address", rs.getString("address"));
					customer.put("city", rs.getString("city"));
					customer.put("state", rs.getString("state"));
					invalidCustomer = false;
				}
			}
		}
		catch (NumberFormatException e) {
			invalidCustomer = true;
		}
	}

	if (invalidCart) {
		out.println("<h2>Something went wrong..</h2>");
		out.println("<p>Your shopping cart is empty. Please add items to your cart before placing an order.</p>");
	}
	else if (invalidCustomer || customer.keySet().isEmpty()) {
		out.println("<h2>Something went wrong..</h2>");
		out.println("<p>Invalid customer ID. Please enter a valid customer ID.</p>");
	}
	else {
		con.setAutoCommit(false);

		int orderId = -1;

// Save order information to database
// Execute the INSERT before retrieving its generated order ID.
		String insertSummarySQL = """
			INSERT INTO ordersummary (customerId, shiptoAddress, shiptoCity, shiptoState, shiptoPostalCode, shiptoCountry, orderDate)
			VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
		""";

// Use retrieval of auto-generated keys.
		try(PreparedStatement pstmt = con.prepareStatement(insertSummarySQL, Statement.RETURN_GENERATED_KEYS)) {

// Set parameters before executing the INSERT.
			pstmt.setInt(1, (Integer) customer.get("customerId"));
			pstmt.setString(2, (String) customer.get("address"));
			pstmt.setString(3, (String) customer.get("city"));
			pstmt.setString(4, (String) customer.get("state"));
			pstmt.setString(5, (String) customer.get("postalCode"));
			pstmt.setString(6, (String) customer.get("country"));

			pstmt.executeUpdate();

			ResultSet keys = pstmt.getGeneratedKeys();
			keys.next();
			orderId = keys.getInt(1);
		}

		String insertProductSQL = """
			INSERT INTO orderproduct 
			(orderId, productId, price, quantity)
			VALUES (?, ?, ?, ?)
		""";

		int totalQuantity = 0;
		double totalAmount = 0.0;

		try (PreparedStatement pstmt = con.prepareStatement(insertProductSQL)) {

// Here is the code to traverse through a HashMap
// Each entry in the HashMap is an ArrayList with item 0-id, 1-name, 2-price, 3-quantity
			Iterator<Map.Entry<String, ArrayList<Object>>> iterator = productList.entrySet().iterator();
			while (iterator.hasNext())
			{ 
				Map.Entry<String, ArrayList<Object>> entry = iterator.next();
				ArrayList<Object> product = (ArrayList<Object>) entry.getValue();
				String productId = (String) product.get(0);
				String price = (String) product.get(2);
				double pr = Double.parseDouble(price);
				int qty = ( (Integer)product.get(3)).intValue();

				pstmt.setInt(1, orderId);
				pstmt.setString(2, productId);
				pstmt.setDouble(3, pr);
				pstmt.setInt(4, qty);
				pstmt.addBatch();

				totalQuantity += qty;

				double total = pr * qty;
				totalAmount += total;

			}

			pstmt.executeBatch();
		}

		String updatePriceSQL = """
			UPDATE ordersummary
			SET totalAmount = ?
			WHERE orderId = ?
		""";

		try (PreparedStatement pstmt = con.prepareStatement(updatePriceSQL)) {
			pstmt.setDouble(1, totalAmount);
			pstmt.setInt(2, orderId);
			pstmt.executeUpdate();
		}

		con.commit();

// Print out order summary

		out.println("<h2>Thanks for ordering!</h2>");

		out.println("<div>");

		out.println("<div>");
		out.println("<p>");
		out.println("<p><strong>Order Confirmation</strong>: " + orderId + "<br />");
		out.println("Your order &#35;"+ orderId + " has been successfully placed.");
		out.println("</p>");
		out.println("</div>");

		out.println("<div>");
		out.println("<p>");
		out.println(customer.get("firstName") + " " + customer.get("lastName") + "<br />");
		out.println(customer.get("address") + "<br />");
		out.println(customer.get("city") + ", " + customer.get("state") + " " + customer.get("postalCode"));
		out.println("</p>");
		out.println("</div>");

		out.println("<div>");
		out.println("<p><strong>Total</strong>: " + NumberFormat.getCurrencyInstance().format(totalAmount) + "</p>");
		out.println("</div>");

		out.println("</div>");

		out.println("<div>");

		out.println("<h3>Your Order (" + totalQuantity + " items)</h3>");

		String selectProductSQL = """
			SELECT P.productId, P.productName, O.quantity, O.price, (O.quantity * O.price) AS total
			FROM orderproduct O JOIN product P ON O.productId = P.productId
			WHERE orderId = ?
		""";

		try (PreparedStatement pstmt = con.prepareStatement(selectProductSQL)) {
			pstmt.setInt(1, orderId);
			try (ResultSet rs = pstmt.executeQuery()) {
				while (rs.next()) {
					out.println("<div>");
					out.println("<p>");
					out.println("<strong>" + rs.getString("productName") + "</strong><br />");
					out.println("Quantity: " + rs.getInt("quantity") + "<br />");
					out.println("Price: " + NumberFormat.getCurrencyInstance().format(rs.getDouble("price")) + "<br />");
					out.println("Total: " + NumberFormat.getCurrencyInstance().format(rs.getDouble("total")));
					out.println("</p>");
					out.println("</div>");
				}
			}
		}

		out.println("</div>");

		out.println("<p><a href='listprod.jsp'>Continue Shopping</a></p>");
		out.println("<p><a href='index.jsp'>Home</a></p>");


// Clear the shopping cart only after all order operations succeed.
		session.removeAttribute("productList");
	}
}
catch (SQLException e) {
	out.println(e);
	
}
%>
</BODY>
</HTML>
