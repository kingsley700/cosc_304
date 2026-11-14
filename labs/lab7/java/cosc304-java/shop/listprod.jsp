<%@ page import="java.sql.*,java.net.URLEncoder" %>
<%@ page import="java.text.NumberFormat" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ include file="jdbc.jsp" %>
<!DOCTYPE html>
<html>
<head>
<title>BCML - shopping</title>
</head>
<body>
<h1>Search for the products you want to buy:</h1>
<form method="get" action="listprod.jsp">
<input type="text" name="productName" size="50">
<input type="submit" value="Submit">
<input type="reset" value="Reset"> (Leave blank for all products)
</form>

<%
String name = request.getParameter("productName");//get the users search in the input
NumberFormat currFormat = NumberFormat.getCurrencyInstance();//dollar signs


try (Connection con = getConnection();
    //get items
     PreparedStatement pstmt = con.prepareStatement(
         "SELECT productId, productName, productPrice " +
         "FROM product " +
         "WHERE productName LIKE ?"
         ))
{
    pstmt.setString(1, "%" + (name == null ? "" : name) + "%");

    try (ResultSet rst = pstmt.executeQuery())
    {   
        //table for whole list
        out.println("<table border='1' cellpadding='8'>");
        out.println("<tr><th>Product Id</th><th>Product Name</th><th>Price</th><th></th></tr>");//headers

        while (rst.next())
        {
            int id = rst.getInt("productId");
            String productName = rst.getString("productName");
            double price = rst.getDouble("productPrice");

            //last 2 lines make link that send info to cart
            out.println("<tr><td>" + id + "</td>"
                      + "<td>" + productName + "</td>"
                      + "<td>" + currFormat.format(price) + "</td>"
                      + "<td><a href='addcart.jsp?id=" + id + "&name=" + URLEncoder.encode(productName, "UTF-8")
                      + "&price=" + price + "'>Add to Cart</a></td></tr>");
        }

        out.println("</table>");
    }
}
catch (SQLException ex)
{
    out.println(ex);
}
%>

</body>
</html>
