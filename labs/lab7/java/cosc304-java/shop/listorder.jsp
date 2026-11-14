
<%@ page import="java.sql.*" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="jdbc.jsp" %>
<!DOCTYPE html>
<html>
<head>
<title>BCML - Orders</title>
</head>
<body>
<h1>Order List</h1>

<%NumberFormat currFormat = NumberFormat.getCurrencyInstance();//money numbers

try (Connection con = getConnection();
     PreparedStatement pstmt = con.prepareStatement(
         "SELECT o.*, c.firstName, c.lastName FROM ordersummary o JOIN customer c ON o.customerId = c.customerId");
     PreparedStatement pstmt2 = con.prepareStatement(
         "SELECT productId, quantity, price FROM orderproduct WHERE orderId = ?"))
{
    // Retrieve orders
    try (ResultSet rst = pstmt.executeQuery())
    {
        while (rst.next())
        {
            int orderId = rst.getInt("orderId");

            out.println("<table border='1' cellpadding='8'>");//overall info for order table
            out.println("<tr><th>Order Id</th><th>Customer Id</th><th>Customer Name</th><th>Total Amount</th></tr>");//headers for order info
            out.println("<tr><td>" + orderId + "</td>"
                      + "<td>" + rst.getInt("customerId") + "</td>"
                      + "<td>" + rst.getString("firstName") + " " + rst.getString("lastName") + "</td>"
                      + "<td>" + currFormat.format(rst.getDouble("totalAmount")) + "</td></tr>");//order info
            out.println("</table><br>");

            pstmt2.setInt(1, orderId);
            try (ResultSet rst2 = pstmt2.executeQuery())//get rst for stuff in order
            {
                if (rst2.next())
                {
                    int totalQuantity = 0;
                    double totalPrice = 0;
                    out.println("<table border='1' cellpadding='8'>");//table of stuff in order
                    out.println("<tr><th>Product Id</th><th>Quantity</th><th>Price</th></tr>");//headers

                    do
                    {
                        int quantity = rst2.getInt("quantity");
                        double price = rst2.getDouble("price");
                        totalQuantity += quantity;
                        totalPrice += quantity * price;

                        out.println("<tr><td>" + rst2.getInt("productId") + "</td>"
                                  + "<td>" + quantity + "</td>"
                                  + "<td>" + currFormat.format(price) + "</td></tr>");//product info
                    } while (rst2.next());

                    out.println("<tr><th>Total:</th><th>" + totalQuantity + "</th><th>" + currFormat.format(totalPrice) + "</th></tr>");//total - almost not needed can rm
                    out.println("</table><br>");
                }
            }
        }
    }
}
catch (SQLException ex)
{
    out.println(ex);
}
%>

</body>
</html>
