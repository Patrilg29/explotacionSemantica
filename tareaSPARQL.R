# Cargamos el paquete
library(SPARQL)

# Guardamos en una variable el endpoint en el que está el grafo
endpoint <- "http://dayhoff.inf.um.es:3043/blazegraph/namespace/synapticVesicle/sparql"

# Generamos las query y las visualizamos
q1 <- "PREFIX ud: <https://um.es/data/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>

SELECT ?label ?proteina ?uriExterna ?longitud 
WHERE {
  ?proteina rdf:type ud:Proteina .
  ?proteina ud:locatedIn ?membrana .
  ?membrana rdf:type ud:MembranaVesicular .
  ?proteina ud:length ?longitud .
  OPTIONAL { ?proteina rdfs:label ?label . }
  OPTIONAL { ?proteina owl:sameAs ?uriExterna . }
  FILTER(?longitud > 300)
}"
consulta1 <- SPARQL(endpoint, q1)
View(as.data.frame(consulta1$results))

q2 <- "PREFIX ud:<https://um.es/data/>
PREFIX rdf:<http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT ?molecula ?funcion ?evidencia
WHERE {
  ?molecula rdf:type ?tipo .
  ?molecula ud:hasFunction ?funcion .
  ?molecula ud:functionSupportedBy ?evidencia .
  ?evidencia rdf:type ud:Experimental .
}
VALUES ?tipo { ud:Proteina ud:ComplejoProteico }"
consulta2 <- SPARQL(endpoint, q2)
View(as.data.frame(consulta2$results))

q3 <- "PREFIX ud: <https://um.es/data/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT ?proteina (COUNT(DISTINCT ?interactuante) AS ?numInteracciones)
WHERE {
  ?proteina rdf:type ud:Proteina .
  ?proteina ud:interactsWith ?interactuante .
  ?interactuante rdf:type ud:Proteina .
}
GROUP BY ?proteina
ORDER BY DESC(?numInteracciones)"
consulta3 <- SPARQL(endpoint, q3)
View(as.data.frame(consulta3$results))

q4 <- "PREFIX ud: <https://um.es/data/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?proteinaA ?proteinaC ?complejo ?proteinaB
WHERE {
  # A y B estan en el mismo complejo
  ?complejo rdf:type ud:ComplejoProteico ;
            ud:hasPart ?proteinaA, ?proteinaB .

  ?proteinaA rdf:type ud:Proteina .
  ?proteinaB rdf:type ud:Proteina .

  FILTER(?proteinaA != ?proteinaB)

  # B interactua con C
  ?proteinaB ud:interactsWith ?proteinaC .
  ?proteinaC rdf:type ud:Proteina .

  # A y C no interactuan directamente
  FILTER(?proteinaA != ?proteinaC)
  FILTER(?proteinaB != ?proteinaC)

  FILTER NOT EXISTS {
    ?proteinaA ud:interactsWith ?proteinaC
  }

  # C no esta en el mismo complejo
  FILTER NOT EXISTS {
    ?complejo ud:hasPart ?proteinaC
  }
}"
consulta4 <- SPARQL(endpoint, q4)
View(as.data.frame(consulta4$results))

q5 <- "PREFIX ud: <https://um.es/data/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>

SELECT DISTINCT ?complejo ?complejoPadre ?funcionPadre
WHERE {
  ?complejo rdf:type ud:ComplejoProteico .

  # Proteina en membrana presinaptica
  ?complejo ud:hasPart ?proteina1 .
  ?proteina1 rdf:type ud:Proteina ;
             ud:locatedIn ud:membranaPresinapticaInst .

  # Proteina en membrana vesicular
  ?complejo ud:hasPart ?proteina2 .
  ?proteina2 rdf:type ud:Proteina ;
             ud:locatedIn ud:membranaVesicularInst .

  FILTER(?proteina1 != ?proteina2)

  # Buscar si otro complejo tiene a este como parte y su funcion molecular
  OPTIONAL {
    ?complejoPadre rdf:type ud:ComplejoProteico ;
                   ud:hasPart ?complejo ;
                   ud:hasFunction ?funcionPadre .
    ?funcionPadre rdf:type ud:FuncionMolecular
    FILTER(?complejoPadre != ?complejo)
  }
}"
consulta5 <- SPARQL(endpoint, q5)
View(as.data.frame(consulta5$results))
