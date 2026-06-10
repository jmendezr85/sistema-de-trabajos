/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // add field
  collection.fields.addAt(21, new Field({
    "hidden": false,
    "id": "bool2660996796",
    "name": "oculto_trafico",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "bool"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // remove field
  collection.fields.removeById("bool2660996796")

  return app.save(collection)
})
