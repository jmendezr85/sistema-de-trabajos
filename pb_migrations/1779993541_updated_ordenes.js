/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // add field
  collection.fields.addAt(19, new Field({
    "hidden": false,
    "id": "number2527535253",
    "max": null,
    "min": null,
    "name": "abono",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // remove field
  collection.fields.removeById("number2527535253")

  return app.save(collection)
})
