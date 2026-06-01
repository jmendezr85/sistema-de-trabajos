/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_839862398")

  // update collection data
  unmarshal({
    "createRule": "",
    "deleteRule": "",
    "indexes": [],
    "listRule": "",
    "updateRule": "",
    "viewRule": ""
  }, collection)

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_839862398")

  // update collection data
  unmarshal({
    "createRule": null,
    "deleteRule": null,
    "indexes": [
      "CREATE INDEX `idx_Wfyo3XcpJo` ON `orden_items` (`orden`)"
    ],
    "listRule": null,
    "updateRule": null,
    "viewRule": null
  }, collection)

  return app.save(collection)
})
