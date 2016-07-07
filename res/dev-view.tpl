<html>
<head>
<style type="text/css">
body,
li,
ul {
    margin: 0
}

ul {
    border: 1px solid red
}

li {
    float: left;
    list-style: none
}

iframe {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    width: 100%;
    height: calc(100% - 40px);
    background-color: #fff;
    border: none;
    border-top: 3px solid #000
}

body {
    background-color: #333;
    font-family: arial;
    font-size: 14px
}

li>a,
li>span {
    color: #eee;
    text-decoration: none;
    display: block;
    padding: 10px
}

li>span {
    color: #aaa
}
</style>
</head>
<body>
  <ul>
  <li><span>yunity dev</span></li>
  <% for (site of sites) { %>
    <li>
      <a href="<% site.href %>" target="<% site.target %>">
        <% site.name %>
      </a>
    </li>
  <% } %>
  </ul>
  <iframe name="aniceiframe" src="<% sites[0].href %>"></iframe>
</body></html>
