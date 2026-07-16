CREATE TABLE IF NOT EXISTS `treasure` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `looted` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `treasure` (`id`, `name`, `looted`) VALUES
(1, 'treasure1', 0),
(2, 'treasure2', 0),
(3, 'treasure3', 0),
(4, 'treasure4', 0);