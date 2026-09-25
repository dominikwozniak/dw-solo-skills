import { readFileSync } from "node:fs"
import { createServer } from "node:http"
import { listRecipes } from "./recipes.js"

const PAGE = new URL("./public/index.html", import.meta.url)

const server = createServer((req, res) => {
  if (req.method === "GET" && req.url === "/api/recipes") {
    res.writeHead(200, { "content-type": "application/json" })
    res.end(JSON.stringify(listRecipes()))
    return
  }
  if (req.method === "GET" && req.url === "/") {
    res.writeHead(200, { "content-type": "text/html" })
    res.end(readFileSync(PAGE))
    return
  }
  res.writeHead(404)
  res.end()
})

server.listen(3000)
