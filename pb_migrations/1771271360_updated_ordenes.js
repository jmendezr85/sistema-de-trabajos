/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // add field
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "number2828208285",
    "max": null,
    "min": null,
    "name": "ticket_no",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2742105131",
    "max": 0,
    "min": 0,
    "name": "codigo_cobro",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "date1573213474",
    "max": "",
    "min": "",
    "name": "pagado_en",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "date"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_3299786656")

  // remove field
  collection.fields.removeById("number2828208285")

  // remove field
  collection.fields.removeById("text2742105131")

  // remove field
  collection.fields.removeById("date1573213474")

  return app.save(collection)
})
