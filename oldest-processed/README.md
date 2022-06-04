## Run this from browser

```
fetch(`https://sundarenius.github.io/static/oldest-processed/oldest-processed.js?id=${Math.random()}`)
.then(function(response) { if (!response.ok) { return false; } return response.blob(); })
.then(function(myBlob) {
  var objectURL = URL.createObjectURL(myBlob);
  var sc = document.createElement("script");
  sc.setAttribute("src", objectURL);
  sc.setAttribute("type", "text/javascript");
  document.head.appendChild(sc);
})
```
