-- ============================================================
-- Baby App — Seed Developmental Milestones
-- ============================================================
-- Based on CDC/WHO developmental milestone guidelines.
-- expected_min_months / expected_max_months = typical range.
-- ============================================================

-- ============================================================
-- GROSS MOTOR (0-24 months)
-- ============================================================

insert into milestone_definitions (category, title, description, expected_min_months, expected_max_months, sort_order) values
('gross_motor', 'Levanta la cabeza brevemente boca abajo', 'Puede levantar la cabeza por unos segundos cuando esta boca abajo', 0, 2, 1),
('gross_motor', 'Sostiene la cabeza firme', 'Mantiene la cabeza estable sin apoyo', 1, 4, 2),
('gross_motor', 'Se voltea (boca abajo a boca arriba)', 'Puede girar de boca abajo a boca arriba', 3, 6, 3),
('gross_motor', 'Se voltea (boca arriba a boca abajo)', 'Puede girar de boca arriba a boca abajo', 4, 7, 4),
('gross_motor', 'Se sienta con apoyo', 'Puede sentarse cuando se le sostiene o con cojines', 4, 6, 5),
('gross_motor', 'Se sienta sin apoyo', 'Se mantiene sentado solo de forma estable', 5, 9, 6),
('gross_motor', 'Se arrastra / gatea', 'Se desplaza arrastrándose o gateando', 6, 10, 7),
('gross_motor', 'Se pone de pie con apoyo', 'Se levanta agarrándose de muebles', 7, 12, 8),
('gross_motor', 'Camina con apoyo (cruising)', 'Camina agarrándose de muebles o de las manos', 8, 13, 9),
('gross_motor', 'Se para solo', 'Se mantiene de pie sin agarrarse', 9, 14, 10),
('gross_motor', 'Primeros pasos solo', 'Da sus primeros pasos independientes', 9, 15, 11),
('gross_motor', 'Camina bien solo', 'Camina de forma estable sin ayuda', 12, 18, 12),
('gross_motor', 'Sube escaleras con ayuda', 'Puede subir escaleras agarrado de la mano o barandal', 12, 20, 13),
('gross_motor', 'Corre', 'Puede correr aunque con poca coordinación', 14, 24, 14),
('gross_motor', 'Patea una pelota', 'Puede patear una pelota hacia adelante', 18, 24, 15);

-- ============================================================
-- FINE MOTOR (0-24 months)
-- ============================================================

insert into milestone_definitions (category, title, description, expected_min_months, expected_max_months, sort_order) values
('fine_motor', 'Agarre reflejo', 'Agarra un dedo u objeto colocado en su mano por reflejo', 0, 2, 1),
('fine_motor', 'Abre y cierra las manos', 'Comienza a abrir y cerrar las manos voluntariamente', 1, 3, 2),
('fine_motor', 'Intenta alcanzar objetos', 'Extiende los brazos para alcanzar objetos', 3, 5, 3),
('fine_motor', 'Agarra objetos voluntariamente', 'Puede agarrar un juguete u objeto con la mano', 3, 6, 4),
('fine_motor', 'Pasa objetos de una mano a otra', 'Transfiere objetos entre las manos', 5, 8, 5),
('fine_motor', 'Pinza inferior (rastrillo)', 'Recoge objetos pequeños con toda la mano', 6, 9, 6),
('fine_motor', 'Pinza fina (pulgar-índice)', 'Recoge objetos pequeños con pulgar e índice', 8, 12, 7),
('fine_motor', 'Señala con el dedo', 'Usa el dedo índice para señalar', 9, 14, 8),
('fine_motor', 'Apila 2 bloques', 'Puede apilar al menos 2 bloques', 12, 18, 9),
('fine_motor', 'Garabatea con crayón', 'Puede hacer marcas en papel con crayón', 12, 18, 10),
('fine_motor', 'Apila 4+ bloques', 'Puede apilar 4 o más bloques', 15, 22, 11),
('fine_motor', 'Usa cuchara (intenta)', 'Intenta alimentarse con cuchara', 12, 18, 12),
('fine_motor', 'Pasa páginas de un libro', 'Puede pasar páginas (varias a la vez)', 12, 20, 13);

-- ============================================================
-- LANGUAGE (0-24 months)
-- ============================================================

insert into milestone_definitions (category, title, description, expected_min_months, expected_max_months, sort_order) values
('language', 'Reacciona a sonidos', 'Se sobresalta o voltea ante sonidos fuertes', 0, 2, 1),
('language', 'Sonrisa social', 'Sonríe en respuesta a la cara o voz de los padres', 1, 3, 2),
('language', 'Gorjea (cooing)', 'Produce sonidos vocálicos como "aaa", "ooo"', 2, 4, 3),
('language', 'Se ríe', 'Produce carcajadas', 3, 5, 4),
('language', 'Balbuceo (babbling)', 'Produce sílabas repetitivas: "bababa", "mamama"', 4, 8, 5),
('language', 'Responde a su nombre', 'Voltea o reacciona cuando escucha su nombre', 5, 9, 6),
('language', 'Dice "mamá" o "papá" (sin significado)', 'Produce las sílabas pero no las asocia', 6, 10, 7),
('language', 'Dice "mamá" o "papá" con significado', 'Usa las palabras refiriéndose a sus padres', 8, 14, 8),
('language', 'Entiende "no"', 'Detiene brevemente la acción cuando se le dice no', 8, 12, 9),
('language', 'Primera palabra (además de mamá/papá)', 'Dice al menos una palabra con significado', 10, 16, 10),
('language', 'Vocabulario 3-5 palabras', 'Usa 3-5 palabras con significado', 12, 18, 11),
('language', 'Señala lo que quiere', 'Señala objetos o comida para pedir', 10, 16, 12),
('language', 'Sigue instrucciones simples', 'Entiende y sigue indicaciones como "dame eso"', 12, 18, 13),
('language', 'Vocabulario 10+ palabras', 'Usa 10 o más palabras', 15, 21, 14),
('language', 'Combina 2 palabras', 'Forma frases de 2 palabras como "más leche"', 18, 24, 15);

-- ============================================================
-- SOCIAL / EMOTIONAL (0-24 months)
-- ============================================================

insert into milestone_definitions (category, title, description, expected_min_months, expected_max_months, sort_order) values
('social', 'Fija la mirada en caras', 'Mira atentamente los rostros cercanos', 0, 2, 1),
('social', 'Sonrisa social', 'Sonríe como respuesta a interacción social', 1, 3, 2),
('social', 'Disfruta interacción social', 'Se emociona y mueve los brazos al interactuar', 2, 4, 3),
('social', 'Reconoce caras familiares', 'Muestra preferencia por padres y cuidadores conocidos', 3, 6, 4),
('social', 'Ansiedad ante extraños', 'Muestra incomodidad o llanto con personas desconocidas', 6, 12, 5),
('social', 'Ansiedad de separación', 'Se molesta cuando el cuidador principal se va', 6, 12, 6),
('social', 'Juega "peek-a-boo"', 'Disfruta y participa en juegos de esconderse', 6, 10, 7),
('social', 'Dice adiós con la mano', 'Hace gesto de despedida', 8, 14, 8),
('social', 'Imita acciones simples', 'Copia acciones como aplaudir o soplar', 8, 14, 9),
('social', 'Muestra afecto (abraza, besa)', 'Demuestra cariño abrazando o besando', 10, 18, 10),
('social', 'Juego paralelo', 'Juega al lado de otros niños (sin interacción directa)', 14, 24, 11),
('social', 'Muestra posesividad ("mío")', 'Defiende sus juguetes o pertenencias', 15, 24, 12),
('social', 'Juego imaginario simple', 'Pretende alimentar un muñeco o hablar por teléfono', 18, 24, 13);

-- ============================================================
-- COGNITIVE (0-24 months)
-- ============================================================

insert into milestone_definitions (category, title, description, expected_min_months, expected_max_months, sort_order) values
('cognitive', 'Sigue objetos con la mirada', 'Puede seguir un objeto en movimiento con los ojos', 0, 3, 1),
('cognitive', 'Descubre sus manos', 'Observa y juega con sus propias manos', 2, 4, 2),
('cognitive', 'Lleva objetos a la boca', 'Explora objetos metiéndolos en la boca', 3, 6, 3),
('cognitive', 'Busca objeto caído', 'Mira hacia donde cayó un objeto', 4, 7, 4),
('cognitive', 'Permanencia del objeto', 'Busca un objeto escondido parcialmente', 6, 10, 5),
('cognitive', 'Explora causa y efecto', 'Repite acciones para ver resultados (sacudir sonajero)', 5, 9, 6),
('cognitive', 'Busca objeto completamente oculto', 'Busca un objeto que se escondió completamente', 8, 12, 7),
('cognitive', 'Usa objetos como herramientas', 'Jala una manta para alcanzar un juguete', 9, 14, 8),
('cognitive', 'Mete y saca objetos de contenedor', 'Puede poner y sacar objetos de una caja', 10, 14, 9),
('cognitive', 'Identifica partes del cuerpo', 'Señala nariz, ojos, boca cuando se le pregunta', 12, 20, 10),
('cognitive', 'Clasifica por forma', 'Puede insertar formas en un clasificador', 14, 22, 11),
('cognitive', 'Juego simbólico', 'Usa objetos para representar otros (bloque = teléfono)', 18, 24, 12),
('cognitive', 'Completa rompecabezas simple', 'Puede completar un rompecabezas de 2-3 piezas', 18, 24, 13);
