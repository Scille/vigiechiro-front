[ ![Codeship Status for Scille/vigiechiro-front](https://codeship.com/projects/2f279570-74c9-0132-ff21-2aca0eeadc1e/status?branch=master)](https://codeship.com/projects/55074)

vigiechiro-front
================

Partie frontend du projet vigie chiro du Muséum national d'histoire naturelle

Activer l'indexation text sur tous les champs des taxons
-------------------------
url de la doc : http://docs.mongodb.org/manual/tutorial/create-text-index-on-multiple-fields/
db.taxons.ensureIndex(
  { "$**": "text" },
  { name: "TaxonsTextIndex" }
)
