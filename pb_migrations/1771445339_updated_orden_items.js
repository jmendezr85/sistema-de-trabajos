/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("pbc_839862398")

  // update collection data
  unmarshal({
    "indexes": [
      "CREATE INDEX `idx_Wfyo3XcpJo` ON `orden_items` (`orden`)"
    ]
  }, collection)

  // add field
  collection.fields.addAt(1, new Field({
    "cascadeDelete": true,
    "collectionId": "pbc_3299786656",
    "hidden": false,
    "id": "relation3777548247",
    "maxSelect": 1,
    "minSelect": 0,
    "name": "orden",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "relation"
  }))

  // add field
  collection.fields.addAt(2, new Field({
    "hidden": false,
    "id": "select3770488265",
    "maxSelect": 1,
    "name": "seccion",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "select",
    "values": [
      "diseno_corte",
      "laser_propalcote_opalina",
      "laser_bond",
      "ploteo_interior",
      "ploteo_exterior",
      "observacion"
    ]
  }))

  // add field
  collection.fields.addAt(3, new Field({
    "autogeneratePattern": "",
    "hidden": false,
    "id": "text2687119104",
    "max": 0,
    "min": 0,
    "name": "descripcion",
    "pattern": "",
    "presentable": false,
    "primaryKey": false,
    "required": false,
    "system": false,
    "type": "text"
  }))

  // add field
  collection.fields.addAt(4, new Field({
    "hidden": false,
    "id": "number400700311",
    "max": null,
    "min": 1,
    "name": "cantidad",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(5, new Field({
    "hidden": false,
    "id": "number2437754975",
    "max": null,
    "min": 0,
    "name": "precio_unitario",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(6, new Field({
    "hidden": false,
    "id": "number3097235076",
    "max": null,
    "min": 0,
    "name": "subtotal",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(7, new Field({
    "hidden": false,
    "id": "number3424758701",
    "max": null,
    "min": 0,
    "name": "costo_laser",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(8, new Field({
    "hidden": false,
    "id": "number2167461261",
    "max": null,
    "min": 0,
    "name": "costo_material",
    "onlyInt": false,
    "presentable": false,
    "required": false,
    "system": false,
    "type": "number"
  }))

  // add field
  collection.fields.addAt(9, new Field({
    "hidden": false,
    "id": "json3622966325",
    "maxSize": 0,
    "name": "meta",
    "presentable": false,
    "required": false,
    "system": false,
    "type": "json"
  }))

  return app.save(collection)
}, (app) => {
  const collection = app.findCollectionByNameOrId("pbc_839862398")

  // update collection data
  unmarshal({
    "indexes": []
  }, collection)

  // remove field
  collection.fields.removeById("relation3777548247")

  // remove field
  collection.fields.removeById("select3770488265")

  // remove field
  collection.fields.removeById("text2687119104")

  // remove field
  collection.fields.removeById("number400700311")

  // remove field
  collection.fields.removeById("number2437754975")

  // remove field
  collection.fields.removeById("number3097235076")

  // remove field
  collection.fields.removeById("number3424758701")

  // remove field
  collection.fields.removeById("number2167461261")

  // remove field
  collection.fields.removeById("json3622966325")

  return app.save(collection)
})
