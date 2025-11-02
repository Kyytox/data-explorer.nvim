Excellente question 👏 — et **oui, c’est une vraie préoccupation** : quand tu exécutes un processus externe et lis son `stdout`, **la taille de la sortie peut devenir un goulot d’étranglement**.

Mais la bonne nouvelle : tu as **plusieurs niveaux de sécurité** selon l’approche utilisée.
Voyons ça clairement 👇

---

## ⚙️ 1. Le problème de base

Quand tu lances DuckDB avec :

```lua
vim.system({ "duckdb", "-csv", "-c", query }, { text = true }):wait()
```

Neovim capture **tout le `stdout`** du processus **en mémoire Lua**.
Donc :

- Si la requête renvoie **des centaines de milliers de lignes**,
  → ça sera **chargé entièrement dans un buffer Lua (string)** avant que tu y accèdes.
- Tu risques :
  - une **consommation mémoire élevée** (voire un crash si tu vas trop loin) ;
  - des lenteurs lors de la concaténation / parsing du CSV en Lua.

Mais il n’y a **pas de “taille max” stricte** imposée par `stdout` ou Neovim — c’est surtout **la mémoire disponible** et **la vitesse de traitement Lua** qui vont te limiter.

---

## 🧠 2. Taille réaliste que tu peux gérer

Sur une machine standard :

| Taille sortie | Risque           | Recommandation                        |
| ------------- | ---------------- | ------------------------------------- |
| < 10 MB       | Aucun            | 👍 Aucun souci                        |
| 10–100 MB     | Possible lenteur | ⚠️ Ok si traitement léger             |
| > 100 MB      | Élevé            | 🚫 À éviter (streaming ou pagination) |

Si tu veux afficher les résultats dans Neovim, il est de toute façon **inutile d’afficher plusieurs milliers de lignes** d’un coup.

---

## 🪄 3. Solutions élégantes selon ton cas

### **A. LIMIT dans la requête**

Toujours une bonne pratique :

```sql
SELECT * FROM 'data.csv' LIMIT 500;
```

C’est trivial mais souvent suffisant.
Si ton plugin sert à explorer des fichiers, tu ne veux jamais afficher 100k lignes d’un coup.

---

### **B. Pagination / streaming côté DuckDB**

DuckDB supporte le **mode streaming CSV** (`duckdb -csv -c`) → tu peux lire les résultats ligne par ligne.

Mais Lua (via `vim.system`) ne stream pas directement.
👉 Si tu veux **streamer en direct**, utilise **`vim.loop.spawn`** ou **`io.popen`** :

Exemple :

```lua
local function run_query_stream(query, on_line)
  local duckdb_cmd = "duckdb"
  local cmd = { duckdb_cmd, "-csv", "-c", query }

  local handle = io.popen(table.concat(cmd, " "))
  if not handle then
    vim.notify("Failed to run duckdb", vim.log.levels.ERROR)
    return
  end

  for line in handle:lines() do
    on_line(line)
  end
  handle:close()
end
```

Et tu l’appelles comme ça :

```lua
run_query_stream("SELECT * FROM 'data.csv' LIMIT 10000", function(line)
  print("Row:", line)
end)
```

✅ Avantage : **tu ne charges jamais tout en mémoire**.
⚠️ Inconvénient : pas asynchrone (bloquant tant que la requête tourne).

---

### **C. Asynchrone + streaming (le top)**

Si tu veux **le beurre et l’argent du beurre**, tu peux combiner :

- `vim.loop.spawn` (libuv)
- lecture progressive sur `stdout`

Exemple (simplifié) :

```lua
local uv = vim.loop

local function run_query_stream_async(query, on_chunk, on_end)
  local duckdb_cmd = "duckdb"
  local cmd = { duckdb_cmd, "-csv", "-c", query }

  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)

  local handle
  handle = uv.spawn(duckdb_cmd, {
    args = { "-csv", "-c", query },
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    handle:close()
    if on_end then on_end(code == 0) end
  end)

  uv.read_start(stdout, function(err, data)
    if err then
      vim.notify("Read error: " .. err, vim.log.levels.ERROR)
      return
    end
    if data then
      on_chunk(data)
    end
  end)
end
```

Tu peux alors :

```lua
run_query_stream_async("SELECT * FROM 'data.csv' LIMIT 10000",
  function(chunk)
    -- chunk = portion de texte CSV
    -- tu peux parser ou afficher au fur et à mesure
  end,
  function(success)
    vim.notify(success and "Done" or "DuckDB failed")
  end
)
```

✅ Avantages :

- Lecture **progressive (stream)** ;
- Non bloquant ;
- Parfait pour fichiers un peu gros.

⚠️ Complexité un peu plus élevée (il faut parser les chunks correctement).

---

## 💡 Conclusion

| Approche                  | Mémoire     | Bloquant | Complexité | Idéal pour                   |
| ------------------------- | ----------- | -------- | ---------- | ---------------------------- |
| `vim.system`              | ❌ élevée   | ❌ non   | ✅ simple  | Requêtes légères             |
| `io.popen`                | ✅ modérée  | ⚠️ oui   | ✅ simple  | Fichiers moyens              |
| `vim.loop.spawn` + stream | ✅ minimale | ✅ non   | ⚙️ moyenne | Fichiers lourds, exploration |

---

### 🏁 Recommandation concrète

- Pour 90 % des cas → `vim.system` (simple, fiable, rapide pour petits/moyens fichiers).
- Si tu veux aller plus loin → implémente **le streaming asynchrone** (`vim.loop.spawn`) : c’est le top pour explorer de “gros fichiers” sans saturer Lua.

---

Souhaites-tu que je te fasse un **exemple complet de fonction Lua “stream async”** prête à mettre dans ton plugin (avec gestion des callbacks et parsing CSV) ?
