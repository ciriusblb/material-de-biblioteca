-- phpMyAdmin SQL Dump
-- version 4.7.4
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 16-12-2017 a las 02:41:51
-- Versión del servidor: 10.1.26-MariaDB
-- Versión de PHP: 7.1.9

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `library`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `selectCod_reserva` (IN `codigo` VARCHAR(10))  BEGIN
  declare varMaxId int;
  declare varCodRe varchar(10);
  declare varCanti int;
  declare varLugar varchar(10);
  declare exit handler for sqlexception
	BEGIN
     select 1 as error;
     rollback;
	END;
 start transaction;
  set varMaxId=(select max(id_reserva) from reservas);
  select codigo_reserva into varCodRe from reservas where id_reserva = varMaxId;
  select cantidad_reservas into varCanti from estadO_u where codigo_usuario = codigo;
  select codigo_reserva into varLugar from reservas where codigo_usuario = codigo and lugar_reserva = 'casa';
  select varCodRe, varCanti,varLugar;
 commit;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spCancelReserva` (IN `codigo` VARCHAR(10))  BEGIN
     declare codLib varchar(10);
     declare codUsu varchar(10);
     declare canLib int;
     declare canRes int;
     select reservas.codigo_libro,reservas.codigo_usuario
     into codLib,codUsu from reservas where codigo_reserva = codigo;
     select cantidad_l into canLib from libros where codigo_libro = codLib;
     select cantidad_reservas into canRes from estado_u where codigo_usuario = codUsu;
     
     delete from reservas where codigo_reserva = codigo;
     update libros set cantidad_l = canLib+1 where codigo_libro=codLib;
     update estado_u set cantidad_reservas = canRes-1 where codigo_usuario=codUsu;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spCodigo` ()  BEGIN
	DECLARE varAux varchar(8);
    DECLARE codImg varchar(50);
	select max(codigo_libro) into varAux from libros;
    select codigo_libro,portada_l from libros where codigo_libro= varAux;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spCodigoArea` (IN `Area` VARCHAR(100))  BEGIN
	SELECT codigo_area from areas where nombre_area=area;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spDevolverLibro` (IN `codigoPres` VARCHAR(10), IN `codigoLib` VARCHAR(10))  BEGIN
declare auxCan int;
declare edit int;
DELETE FROM prestamos where codigo_prestamo = codigoPres;
select cantidad_l,editado into auxCan,edit from libros where codigo_libro = codigoLib;
set auxCan = auxCan+1;
set edit = edit+1;
update libros set cantidad_l = auxCan , editado=edit where codigo_libro = codigoLib;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spGetBook` (IN `codigoL` VARCHAR(10), IN `codigoU` VARCHAR(10))  BEGIN
     declare auxRes varchar(10);
     declare auxIdE int;
     declare auxPres varchar(10);
     select codigo_reserva into auxRes from reservas where codigo_libro = codigoL and codigo_usuario = codigoU;
     select id_espera into auxIdE from esperas where codigo_libro = codigoL and codigo_usuario = codigoU;
     select codigo_prestamo into auxPres from prestamos where codigo_libro = codigoL and codigo_usuario = codigoU;
     select libros.*, areas.nombre_area,auxRes,auxIdE,auxPres from libros,areas
     where libros.codigo_libro=codigoL and libros.area_l = areas.codigo_area;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spGetHistorial` ()  BEGIN
select historial.id_historial,historial.codigo_libro,libros.`area_l`,areas.nombre_area from historial,libros,areas
where libros.area_l = areas.codigo_area and historial.codigo_libro = libros.codigo_libro;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spGetLastBooks` ()  BEGIN
     declare varMaxId int;
     set varMaxId=(select max(id_libro) from libros);
     select libros.*,areas.ruta_area from libros,areas
     where libros.id_libro=varMaxId and libros.area_l = areas.codigo_area;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spGetPublicacion` ()  BEGIN
     declare varMaxId int;
     set varMaxId=(select max(id_publicacion) from publicaciones);
     select * from publicaciones where id_publicacion=varMaxId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spGetReservas` ()  BEGIN
declare auxID int;
set auxID = (select max(id_reserva) from reservas);
SELECT reservas.*,libros.titulo_l,libros.portada_l,libros.descripcion_l,libros.autor_l,usuarios.nombre_usuario,usuarios.apellido_usuario
from reservas,libros,usuarios
where reservas.codigo_libro=libros.codigo_libro and reservas.codigo_usuario = usuarios.codigo_usuario and reservas.id_reserva = auxID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spInfoBook` (IN `codigoLibro` VARCHAR(10), IN `codigoUsuario` VARCHAR(10))  BEGIN
select codigo_reserva from reservas
where codigo_libro = codigoLibro and codigo_usuario = codigoUsuario;
end$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spInsertNotificacion` (IN `codigoU` VARCHAR(10), IN `codigoL` VARCHAR(10))  BEGIN
declare auxTit varchar(50);
declare auxDes longtext;
declare maxID int;
select titulo_l into auxTit from libros where codigo_libro = codigoL;
set auxDes = concat('Ya esta disponible el libro ',auxTit,' tiene la opcion de reservarlo');
insert into notificaciones(codigo_usuario,codigo_libro,descripcion,estado,tipo) values(codigoU,codigoL,auxDes,0,'info');
delete from esperas where codigo_libro=codigoL and codigo_usuario = codigoU;
select MAX(id_notificacion) into maxID from notificaciones;
select notificaciones.*,libros.area_l,libros.portada_l from notificaciones,libros where id_notificacion = maxID and notificaciones.codigo_libro = libros.codigo_libro;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spLastReserva` (IN `cod_reserva` VARCHAR(10))  BEGIN
 select libros.*,reservas.codigo_reserva,reservas.fecha_inicio,reservas.fecha_limite,
 usuarios.codigo_usuario
 from libros,reservas,usuarios
 where libros.codigo_libro=reservas.codigo_libro
 and usuarios.codigo_usuario=reservas.codigo_usuario
 and reservas.codigo_reserva=cod_reserva;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spNewUsuario` ()  BEGIN
declare varAux int;
set varAux=(select max(id_estado) from estado_u);
SELECT usuarios.*,estado_u.penalizado
from usuarios,estado_u
where usuarios.codigo_usuario=estado_u.codigo_usuario and estado_u.id_estado = varAux;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spNotificar` ()  BEGIN
     declare varMaxId int;
     set varMaxId=(select max(id_notificacion) from notificaciones);
     select notificaciones.*,libros.area_l,libros.portada_l
     from notificaciones,libros where id_notificacion = varMaxId and notificaciones.codigo_libro=libros.codigo_libro;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spNotificarLibroEditado` (IN `codigoUsu` VARCHAR(10), IN `codigoLib` VARCHAR(10))  BEGIN
delete from esperas where codigo_libro = codigoLib;
insert into notificaciones(codigo_usuario,codigo_libro,descripcion,estado,tipo) values
(codigoUsu,codigoLib,CONCAT('Ya esta disponible el libro', fnCodLibro(codigoLib),'tiene la opcion de reservarlo'),0,'info');
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spRemoveReservas` ()  BEGIN
 DECLARE done BOOLEAN DEFAULT FALSE;
declare auxID int;
declare fechaActual timestamp;
declare auxFecha varchar(50);
 declare c1 cursor for
  select id_reserva,fecha_limite from reservas;
  open c1;
   c1_loop:loop
   fetch c1 into auxID,auxFecha;
   if done then leave c1_loop;end if;
   set fechaActual= (select now());
   if(auxFecha>fechaActual) then
       update reservas set lugar_reserva = 'sala';
   end if;
   end loop c1_loop;
  close c1;
  select*from reservas;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spReservar` (IN `cod_reserva` VARCHAR(10), IN `cod_libro` VARCHAR(10), IN `cod_usuario` VARCHAR(10), IN `fecha_ini` VARCHAR(50), IN `fecha_lim` VARCHAR(50), IN `lugar` VARCHAR(10))  BEGIN
  declare auxcod varchar(10);
  declare auxcanLibro int;
  declare auxcanReserva int;
  declare exit handler for sqlexception
	BEGIN
     select 1 as error;
     rollback;
	END;
 start transaction;
  set auxcod =(select id_estado from estado_u where codigo_usuario=cod_usuario);
  insert into reservas(codigo_reserva,codigo_libro,codigo_usuario,fecha_inicio,fecha_limite,lugar_reserva,estado) values(cod_reserva,cod_libro,cod_usuario,fecha_ini,fecha_lim,lugar,auxcod);
  set auxcanLibro =(select cantidad_l from libros where codigo_libro = cod_libro);
  set auxcanLibro = auxcanLibro-1;
  update libros set cantidad_l = auxcanLibro where codigo_libro = cod_libro;
  set auxcanReserva =(select cantidad_reservas from estado_u where codigo_usuario = cod_usuario);
  set auxcanReserva = auxcanReserva+1;
  update estado_u set cantidad_reservas = auxcanReserva,estado_reserva = 'reservado' where codigo_usuario = cod_usuario;
  select libros.cantidad_l from libros where codigo_libro = cod_libro;
 commit;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spUpdateReservas` ()  BEGIN
 select libros.*,reservas.codigo_reserva,reservas.fecha_inicio,reservas.fecha_limite,usuarios.codigo_usuario
 from libros,reservas,usuarios
 where libros.codigo_libro=reservas.codigo_libro
 and usuarios.codigo_usuario=reservas.codigo_usuario
 and reservas.codigo_usuario=.usuarios.codigo_usuario;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `spVerReservas` (IN `cod_usuario` VARCHAR(10))  BEGIN
 select libros.*,reservas.codigo_reserva,reservas.fecha_inicio,reservas.fecha_limite,usuarios.codigo_usuario
 from libros,reservas,usuarios
 where libros.codigo_libro=reservas.codigo_libro
 and usuarios.codigo_usuario=reservas.codigo_usuario
 and reservas.codigo_usuario=cod_usuario;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `fnActual` () RETURNS TIMESTAMP BEGIN
declare varAux TIMESTAMP;
	set varAux = (SELECT NOW());

RETURN varAux;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fnCodLibro` (`cod` VARCHAR(10)) RETURNS VARCHAR(30) CHARSET latin1 BEGIN
declare varAux varchar(30);
	set varAux = (select titulo_l from libros  where codigo_libro = cod);

RETURN varAux;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `fnFecha` () RETURNS TIMESTAMP BEGIN
declare varAux TIMESTAMP;
	set varAux = (SELECT NOW()+INTERVAL 2 day);

RETURN varAux;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `antiguas_contrasenas`
--

CREATE TABLE `antiguas_contrasenas` (
  `id_antiguo` int(11) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `contrasena_usuario` longtext NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `antiguas_contrasenas`
--

INSERT INTO `antiguas_contrasenas` (`id_antiguo`, `codigo_usuario`, `contrasena_usuario`, `fecha`) VALUES
(1, '15121041', '218281dd2c74727f', '2017-12-16 00:47:10');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `areas`
--

CREATE TABLE `areas` (
  `codigo_area` varchar(10) NOT NULL,
  `nombre_area` varchar(50) NOT NULL,
  `ruta_area` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `areas`
--

INSERT INTO `areas` (`codigo_area`, `nombre_area`, `ruta_area`) VALUES
('area_01', 'Medicina Veterinaria', 'Medicina_Veterinaria'),
('area_02', 'Matemática', 'Matematica'),
('area_03', 'Administración', 'Administracion'),
('area_04', 'Obras Literarias', 'Obras_Literarias'),
('area_05', 'Computación e Informática', 'Computacion_e_Informatica'),
('area_06', 'Ciencias Políticas', 'Ciencias_Politicas'),
('area_07', 'Sociología', 'Sociologia'),
('area_08', 'Economía', 'Economia'),
('area_09', 'Física', 'Fisica'),
('area_10', 'Agronomía y Forestal', 'Agronomia_y_Forestal'),
('area_11', 'Química', 'Quimica'),
('area_12', 'Contabilidad', 'Contabilidad'),
('area_13', 'Biología', 'Biologia'),
('area_14', 'Ingenierías', 'Ingenierias'),
('area_15', 'Estadística', 'Estadistica'),
('area_16', 'Enfermería', 'Enfermeria'),
('area_17', 'Historia', 'Historia'),
('area_18', 'Turismo y Hotelería', 'Turismo_y_Hoteleria'),
('area_19', 'Medicina', 'Medicina'),
('area_20', 'Geografía', 'Geografia');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `comentarios`
--

CREATE TABLE `comentarios` (
  `id_comentario` int(11) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `comentario_usuario` longtext NOT NULL,
  `hora_comentada` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `comentarios`
--

INSERT INTO `comentarios` (`id_comentario`, `codigo_libro`, `codigo_usuario`, `comentario_usuario`, `hora_comentada`) VALUES
(1, 'LI000006', '15121041', 'esta bueno', '15 Dec, 2017 7:55'),
(2, 'LI000020', '15121041', 'nuevo libro que alegria', '15 Dec, 2017 8:25'),
(3, 'LI000010', '15121041', 'que buen libro', '15 Dec, 2017 8:30'),
(4, 'LI000010', '15121010', 'es chevere', '15 Dec, 2017 8:30');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `esperas`
--

CREATE TABLE `esperas` (
  `id_espera` int(11) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `estado_u`
--

CREATE TABLE `estado_u` (
  `id_estado` int(11) NOT NULL,
  `codigo_usuario` varchar(10) DEFAULT NULL,
  `cantidad_reservas` int(11) NOT NULL,
  `estado_reserva` varchar(50) NOT NULL,
  `estado_prestado` varchar(50) NOT NULL,
  `penalizado` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `estado_u`
--

INSERT INTO `estado_u` (`id_estado`, `codigo_usuario`, `cantidad_reservas`, `estado_reserva`, `estado_prestado`, `penalizado`) VALUES
(1, '15121041', 6, 'reservado', 'no prestado', 'Libre'),
(2, '15121010', 1, 'reservado', 'no prestado', 'Libre');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `historial`
--

CREATE TABLE `historial` (
  `id_historial` int(11) NOT NULL,
  `fecha_salida` varchar(50) NOT NULL,
  `fecha_limite` varchar(50) NOT NULL,
  `fecha_entrega` varchar(50) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `historial`
--

INSERT INTO `historial` (`id_historial`, `fecha_salida`, `fecha_limite`, `fecha_entrega`, `codigo_usuario`, `codigo_libro`) VALUES
(1, '2017-10-03 09:09:41', '2017-10-03 21:00:00', '2017-10-03 11:12:34', '15121041', 'LI000006'),
(2, '2017-10-03 09:12:31', '2017-10-03 21:00:00', '2017-10-03 13:12:36', '15121041', 'LI000006'),
(3, '2017-10-06 07:14:07', '2017-10-06 21:00:00', '2017-10-06 09:14:15', '15121002', 'LI000006'),
(4, '2017-11-06 09:14:10', '2017-11-06 21:00:00', '2017-11-06 11:14:16', '15121041', 'LI000016'),
(5, '2017-11-07 10:14:08', '2017-11-07 21:00:00', '2017-11-07 12:14:18', '15121002', 'LI000016'),
(6, '2017-11-07 15:14:12', '2017-11-07 21:00:00', '2017-11-07 16:14:20', '15121041', 'LI000006'),
(7, '2017-11-08 17:14:42', '2017-11-08 21:00:00', '2017-11-08 19:14:57', '15121002', 'LI000016'),
(8, '2017-11-08 09:14:45', '2017-11-08 21:00:00', '2017-11-08 11:14:59', '15121041', 'LI000006'),
(9, '2017-11-09 08:14:47', '2017-11-09 21:00:00', '2017-11-09 10:15:05', '15121002', 'LI000006'),
(10, '2017-04-09 09:14:49', '2017-04-09 21:00:00', '2017-04-09 10:15:07', '15121002', 'LI000002'),
(11, '2017-04-10 16:14:51', '2017-04-10 21:00:00', '2017-04-10 18:15:09', '15121041', 'LI000002'),
(12, '2017-04-10 09:14:52', '2017-04-10 21:00:00', '2017-04-10 11:15:11', '15121002', 'LI000002'),
(13, '2017-04-13 13:15:16', '2017-04-13 21:00:00', '2017-04-13 15:15:27', '15121002', 'LI000002'),
(14, '2017-11-13 15:15:18', '2017-11-13 21:00:00', '2017-11-13 17:15:29', '15121002', 'LI000002'),
(15, '2017-11-14 07:15:21', '2017-11-14 21:00:00', '2017-11-14 09:15:31', '15121041', 'LI000003'),
(16, '2017-11-14 09:15:23', '2017-11-14 21:00:00', '2017-11-14 10:15:33', '15121002', 'LI000003'),
(17, '2017-03-03 09:09:41', '2017-03-03 21:00:00', '2017-03-03 11:12:34', '15121002', 'LI000003'),
(18, '2017-03-03 09:12:31', '2017-03-03 21:00:00', '2017-03-03 13:12:36', '15121041', 'LI000003'),
(19, '2017-03-06 07:14:07', '2017-03-06 21:00:00', '2017-03-06 09:14:15', '15121041', 'LI000003'),
(20, '2017-03-06 09:14:10', '2017-03-06 21:00:00', '2017-03-06 11:14:16', '15121002', 'LI000003'),
(21, '2017-03-07 10:14:08', '2017-11-07 21:00:00', '2017-11-07 12:14:18', '15121002', 'LI000003'),
(22, '2017-11-07 15:14:12', '2017-11-07 21:00:00', '2017-11-07 16:14:20', '15121041', 'LI000004'),
(23, '2017-11-08 17:14:42', '2017-11-08 21:00:00', '2017-11-08 19:14:57', '15121002', 'LI000004'),
(24, '2017-11-08 09:14:45', '2017-11-08 21:00:00', '2017-11-08 11:14:59', '15121002', 'LI000004'),
(25, '2017-11-09 08:14:47', '2017-11-09 21:00:00', '2017-11-09 10:15:05', '15121002', 'LI000004'),
(26, '2017-04-09 09:14:49', '2017-04-09 21:00:00', '2017-04-09 10:15:07', '15121041', 'LI000004'),
(27, '2017-04-10 16:14:51', '2017-04-10 21:00:00', '2017-04-10 18:15:09', '16121001', 'LI000004'),
(28, '2017-04-10 09:14:52', '2017-04-10 21:00:00', '2017-04-10 11:15:11', '15121002', 'LI000005'),
(29, '2017-04-13 13:15:16', '2017-04-13 21:00:00', '2017-04-13 15:15:27', '16121001', 'LI000017'),
(30, '2017-11-13 15:15:18', '2017-11-13 21:00:00', '2017-11-13 17:15:29', '16121001', 'LI000017'),
(31, '2017-11-14 07:15:21', '2017-11-14 21:00:00', '2017-11-14 09:15:31', '16121001', 'LI000017'),
(32, '2017-11-14 09:15:23', '2017-11-14 21:00:00', '2017-11-14 10:15:33', '15121002', 'LI000005'),
(33, '2017-05-06 09:14:10', '2017-05-06 21:00:00', '2017-05-06 11:14:16', '15121002', 'LI000006'),
(34, '2017-05-07 10:14:08', '2017-05-07 21:00:00', '2017-05-07 12:14:18', '15121041', 'LI000006'),
(35, '2017-05-07 15:14:12', '2017-05-07 21:00:00', '2017-05-07 16:14:20', '16121001', 'LI000006'),
(36, '2017-05-08 17:14:42', '2017-05-08 21:00:00', '2017-05-08 19:14:57', '16121001', 'LI000006'),
(37, '2017-05-08 09:14:45', '2017-05-08 21:00:00', '2017-05-08 11:14:59', '15121041', 'LI000006'),
(38, '2017-05-09 08:14:47', '2017-05-09 21:00:00', '2017-05-09 10:15:05', '16121001', 'LI000006'),
(39, '2017-06-06 09:14:10', '2017-06-06 21:00:00', '2017-06-06 11:14:16', '16121001', 'LI000006'),
(40, '2017-06-07 10:14:08', '2017-06-07 21:00:00', '2017-06-07 12:14:18', '16121001', 'LI000006'),
(41, '2017-06-07 15:14:12', '2017-06-07 21:00:00', '2017-06-07 16:14:20', '16121001', 'LI000006'),
(42, '2017-06-08 17:14:42', '2017-06-08 21:00:00', '2017-06-08 19:14:57', '16121001', 'LI000006'),
(43, '2017-06-08 09:14:45', '2017-06-08 21:00:00', '2017-06-08 11:14:59', '15121041', 'LI000006'),
(44, '2017-06-09 08:14:47', '2017-06-09 21:00:00', '2017-06-09 10:15:05', '15121041', 'LI000006'),
(45, '2017-06-09 09:14:49', '2017-06-09 21:00:00', '2017-06-09 10:15:07', '16121001', 'LI000006'),
(46, '2017-06-10 16:14:51', '2017-06-10 21:00:00', '2017-06-10 18:15:09', '15121041', 'LI000006'),
(47, '2017-06-10 09:14:52', '2017-06-10 21:00:00', '2017-06-10 11:15:11', '16121001', 'LI000006'),
(48, '2017-06-13 13:15:16', '2017-06-13 21:00:00', '2017-06-13 15:15:27', '16121001', 'LI000006'),
(49, '2017-07-08 17:14:42', '2017-07-08 21:00:00', '2017-07-08 19:14:57', '15121041', 'LI000006'),
(50, '2017-07-08 09:14:45', '2017-07-08 21:00:00', '2017-07-08 11:14:59', '16121001', 'LI000006'),
(51, '2017-07-09 08:14:47', '2017-07-09 21:00:00', '2017-07-09 10:15:05', '16121001', 'LI000006'),
(52, '2017-07-10 09:14:52', '2017-07-10 21:00:00', '2017-07-10 11:15:11', '16121001', 'LI000006'),
(53, '2017-07-13 13:15:16', '2017-07-13 21:00:00', '2017-07-13 15:15:27', '16121001', 'LI000006'),
(54, '2017-07-14 09:15:23', '2017-07-14 21:00:00', '2017-07-14 10:15:33', '15121041', 'LI000006'),
(55, '2017-07-06 09:14:10', '2017-07-06 21:00:00', '2017-07-06 11:14:16', '15121041', 'LI000006'),
(56, '2017-08-10 16:14:51', '2017-08-10 21:00:00', '2017-08-10 18:15:09', '15121041', 'LI000006'),
(57, '2017-08-10 09:14:52', '2017-08-10 21:00:00', '2017-08-10 11:15:11', '15121041', 'LI000007'),
(58, '2017-08-13 13:15:16', '2017-08-13 21:00:00', '2017-08-13 15:15:27', '15121041', 'LI000007'),
(59, '2017-08-03 09:12:31', '2017-08-03 21:00:00', '2017-08-03 13:12:36', '15121041', 'LI000015'),
(60, '2017-09-09 09:14:49', '2017-09-09 21:00:00', '2017-09-09 10:15:07', '15121041', 'LI000015'),
(61, '2017-09-10 16:14:51', '2017-09-10 21:00:00', '2017-09-10 18:15:09', '15121041', 'LI000007'),
(62, '2017-09-10 09:14:52', '2017-09-10 21:00:00', '2017-09-10 11:15:11', '15121041', 'LI000007'),
(63, '2017-09-14 09:15:23', '2017-09-14 21:00:00', '2017-09-14 10:15:33', '15121041', 'LI000008'),
(64, '2017-09-03 09:09:41', '2017-09-03 21:00:00', '2017-09-03 11:12:34', '16121001', 'LI000008'),
(65, '2017-09-03 09:12:31', '2017-09-03 21:00:00', '2017-09-03 13:12:36', '16121001', 'LI000018'),
(66, '2017-09-07 10:14:08', '2017-09-07 21:00:00', '2017-09-07 12:14:18', '15121041', 'LI000018'),
(67, '2017-09-08 17:14:42', '2017-09-08 21:00:00', '2017-09-08 19:14:57', '16121001', 'LI000018'),
(68, '2017-11-15 10:05:45', '2017-11-15 21:00:00', '2017-11-15 10:27:20', '16121001', 'LI000008'),
(69, '2017-11-15 10:07:38', '2017-11-15 21:00:00', '2017-11-15 10:27:22', '16121001', 'LI000008'),
(70, '2017-11-15 10:09:21', '2017-11-15 21:00:00', '2017-11-15 10:27:24', '16121001', 'LI000008'),
(71, '2017-11-15 10:25:16', '2017-11-15 21:00:00', '2017-11-15 10:27:25', '15121041', 'LI000009'),
(72, '2017-11-15 11:25:21', '2017-11-15 21:00:00', '2017-11-15 11:35:47', '16121001', 'LI000009'),
(73, '2017-11-15 11:04:55', '2017-11-15 21:00:00', '2017-11-15 11:37:09', '15121041', 'LI000009'),
(74, '2017-11-15 11:27:42', '2017-11-15 21:00:00', '2017-11-15 11:38:28', '16121001', 'LI000009'),
(75, '2017-11-15 11:42:22', '2017-11-15 21:00:00', '2017-11-15 11:43:48', '16121001', 'LI000009'),
(76, '2017-11-15 11:51:08', '2017-11-15 21:00:00', '2017-11-15 11:52:46', '15121041', 'LI000009'),
(77, '2017-11-15 12:10:52', '2017-11-15 21:00:00', '2017-11-15 12:12:07', '16121001', 'LI000009'),
(78, '2017-11-15 11:07:32', '2017-11-15 21:00:00', '2017-11-15 12:15:37', '16121001', 'LI000010'),
(79, '2017-11-15 11:07:32', '2017-11-15 21:00:00', '2017-11-15 12:15:43', '15121002', 'LI000010'),
(80, '2017-11-15 11:16:34', '2017-11-15 21:00:00', '2017-11-15 12:16:22', '16121001', 'LI000019'),
(81, '2017-11-15 12:17:13', '2017-11-15 21:00:00', '2017-11-15 12:18:16', '15121041', 'LI000010'),
(82, '15/11/2017 12:33:36', '15/11/2017 21:00:00', '2017-11-15 12:40:15', '70229265', 'LI000010'),
(83, '2017-11-15 10:35:54', '2017-11-15 21:00:00', '2017-11-15 12:41:03', '15121002', 'LI000010'),
(84, '2017-11-15 11:21:38', '2017-11-15 21:00:00', '2017-11-15 12:41:09', '15121002', 'LI000010'),
(85, '2017-11-15 10:47:09', '2017-11-15 21:00:00', '2017-11-15 12:41:17', '15121002', 'LI000010'),
(86, '2017-11-15 10:55:06', '2017-11-15 21:00:00', '2017-11-15 12:41:20', '15121002', 'LI000010'),
(87, '2017-11-15 10:56:21', '2017-11-15 21:00:00', '2017-11-15 12:41:22', '15121002', 'LI000010'),
(88, '2017-11-15 17:25:29', '2017-11-15 17:25:29', '2017-11-15 17:33:27', '15121041', 'LI000011'),
(89, '2017-11-15 17:28:44', '2017-11-14 17:28:44', '2017-11-15 17:33:29', '15121002', 'LI000011'),
(90, '2017-11-17 09:34:29', '2017-11-17 21:00:00', '2017-11-17 09:34:59', '15121041', 'LI000011'),
(91, '2017-11-17 09:35:33', '2017-11-17 21:00:00', '2017-11-17 09:35:44', '15121041', 'LI000011'),
(92, '2017-11-17 09:39:58', '2017-11-17 21:00:00', '2017-11-17 09:40:06', '15121041', 'LI000012'),
(93, '2017-11-17 09:42:36', '2017-11-17 21:00:00', '2017-11-17 09:42:42', '15121002', 'LI000012'),
(94, '2017-11-17 09:57:40', '2017-11-20 09:57:40', '2017-11-17 09:57:51', '15121041', 'LI000012'),
(95, '2017-11-17 11:39:46', '2017-11-17 21:00:00', '2017-11-17 11:41:15', '15121041', 'LI000013'),
(96, '2017-11-17 12:08:49', '2017-11-17 21:00:00', '2017-11-17 12:09:11', '15121002', 'LI000013'),
(97, '2017-11-17 12:30:21', '2017-11-17 21:00:00', '2017-11-17 12:30:35', '15121041', 'LI000013'),
(98, '2017-11-17 10:31:57', '2017-11-17 21:00:00', '2017-11-17 15:22:04', '15121002', 'LI000013'),
(99, '2017-11-24 19:23:35', '2017-11-24 21:00:00', '2017-11-24 19:28:29', '15121002', 'LI000013'),
(100, '2017-12-03 19:43:38', '2017-12-03 21:00:00', '2017-12-03 19:43:49', '15121041', 'LI000014'),
(101, '2017-11-09 08:14:47', '2017-11-09 21:00:00', '2017-11-09 10:15:05', '15121041', 'LI000014'),
(102, '2017-12-09 08:14:47', '2017-12-09 21:00:00', '2017-12-09 10:15:05', '15121041', 'LI000014'),
(103, '2017-12-14 23:26:15', '2017-12-14 21:00:00', '', '15121041', 'LI000002'),
(104, '2017-12-14 23:26:24', '2017-12-14 21:00:00', '', '15121041', 'LI000011'),
(105, '2017-12-15 10:05:18', '2017-12-15 21:00:00', '', '15121041', 'LI000002'),
(106, '2017-12-15 10:16:23', '2017-12-15 21:00:00', '', '15121002', 'LI000002'),
(107, '2017-12-15 10:23:25', '2017-12-15 21:00:00', '', '15121041', 'LI000002'),
(108, '2017-12-15 10:26:10', '2017-12-15 21:00:00', '', '15121041', 'LI000006'),
(109, '2017-12-15 10:28:29', '2017-12-15 21:00:00', '', '15121041', 'LI000006'),
(110, '2017-12-15 10:38:29', '2017-12-15 21:00:00', '', '15121002', 'LI000015'),
(111, '2017-12-14 23:30:36', '2017-12-14 21:00:00', '', '15121041', 'LI000009'),
(112, '2017-12-15 00:34:09', '2017-12-15 21:00:00', '', '15121041', 'LI000008'),
(113, '2017-12-15 12:07:21', '2017-12-15 21:00:00', '', '15121041', 'LI000006'),
(114, '2017-12-15 12:41:37', '2017-12-15 21:00:00', '', '15121041', 'LI000014'),
(115, '2017-12-14 23:25:54', '2017-12-14 21:00:00', '', '15121002', 'LI000008'),
(116, '2017-12-15 16:19:26', '2017-12-15 21:00:00', '', '15121041', 'LI000015'),
(117, '2017-12-15 16:30:45', '2017-12-17 16:30:45', '', '15121001', 'LI000024'),
(118, '2017-12-15 16:37:57', '2017-12-15 21:00:00', '', '15121002', 'LI000009'),
(119, '2017-12-15 20:20:42', '2017-12-15 21:00:00', '', '15121010', 'LI000006'),
(120, '2017-12-15 20:26:07', '2017-12-15 21:00:00', '', '15121041', 'LI000020');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `libros`
--

CREATE TABLE `libros` (
  `id_libro` int(11) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL,
  `titulo_l` varchar(30) DEFAULT NULL,
  `autor_l` varchar(50) DEFAULT NULL,
  `descripcion_l` longtext,
  `portada_l` varchar(50) NOT NULL,
  `cantidad_l` int(11) DEFAULT NULL,
  `area_l` varchar(10) DEFAULT NULL,
  `fecha_ingreso` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `editado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `libros`
--

INSERT INTO `libros` (`id_libro`, `codigo_libro`, `titulo_l`, `autor_l`, `descripcion_l`, `portada_l`, `cantidad_l`, `area_l`, `fecha_ingreso`, `editado`) VALUES
(1, 'LI000001', 'Contabilidad Financiera', 'Paloma del Campo Moreno', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO001.jpg', 19, 'area_12', '2017-03-13 04:20:32', 1),
(2, 'LI000002', 'Estadística para Ingenieros', 'Willian Navidi', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO002.jpg', 20, 'area_15', '2017-03-13 04:20:32', 0),
(3, 'LI000003', 'Fundamentos de Administracion', 'Jose G. Garcia Martinez', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO003.jpg', 9, 'area_03', '2017-03-13 04:20:32', 0),
(4, 'LI000004', 'Técnica Contable', 'Rafael D. Martínez', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO004.jpg', 20, 'area_12', '2017-03-13 04:20:32', 0),
(5, 'LI000005', 'Liderasgo', 'Robert N. Lussier', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO005.jpg', 23, 'area_07', '2017-03-13 04:20:32', 0),
(6, 'LI000006', 'Matemáticas Financieras', 'Robert L.Brown', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO006.jpg', 0, 'area_02', '2017-03-13 04:20:32', 2),
(7, 'LI000007', 'Metodología de Investigación', 'Cesar A. Bernal', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO007.jpg', 12, 'area_07', '2017-04-13 04:20:32', 0),
(8, 'LI000008', 'Carpeta de Investigación', 'José Alberto Ortiz Ruiiz', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO008.jpg', 14, 'area_07', '2017-04-13 04:20:32', 0),
(10, 'LI000010', 'Managerial Finance', 'Lawrence J. Gitman', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO010.jpg', 1, 'area_06', '2017-05-13 04:20:32', 0),
(11, 'LI000011', 'Derecho Administrativo', 'José Antonio Tardío', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO011.jpg', 7, 'area_06', '2017-05-13 04:20:32', 0),
(12, 'LI000012', 'AlgebraElemental', 'Carlos Prieto de Castro', 'ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO012.jpg', 1, 'area_02', '2017-06-13 04:20:32', 1),
(13, 'LI000013', 'Dinámica', 'R. C. Hibbeler', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO013.jpg', 9, 'area_09', '2017-06-13 04:20:32', 0),
(14, 'LI000014', 'Física Universitaria', 'Sears Zemansky', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO014.jpg', 20, 'area_09', '2017-06-13 04:20:32', 0),
(15, 'LI000015', 'Geometría Moderna', 'Leandro Tortosa Grau', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO015.jpg', 9, 'area_02', '2017-07-13 04:20:32', 0),
(16, 'LI000016', 'Ingeniería Ambiental', 'Julie BethZimmerman', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO016.jpg', 5, 'area_10', '2017-08-13 04:20:32', 0),
(17, 'LI000017', 'Matemática Aplicada', 'María Josefa Cánavas', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO017.jpg', 1, 'area_02', '2017-08-13 04:20:32', 0),
(18, 'LI000018', 'Matemáticas Basicas', 'Carlos Rojas Álvarez', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO018.jpg', 15, 'area_02', '2017-08-13 04:20:32', 0),
(19, 'LI000019', 'Quimica General', 'Javier Cruz Guardado', 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullavmo laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.', 'LIBRO019.jpg', 19, 'area_11', '2017-08-13 04:20:32', 0),
(20, 'LI000020', 'Enfermería en la Unidad de Cui', 'Anonimo', 'orem Ipsum es simplemente el texto de relleno de las imprentas y archivos de texto. Lorem Ipsum ha sido el texto de relleno estándar de las industrias desde el año 1500, cuando un impresor (N. del T. persona que se dedica a la imprenta) desconocido usó una galería de textos y los mezcló de tal manera que logró hacer un libro de textos especimen. No sólo sobrevivió 500 años, sino que tambien ingresó como tex', 'LIBRO020.jpg', 4, 'area_16', '2017-12-16 01:25:25', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id_notificacion` int(11) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL,
  `descripcion` longtext NOT NULL,
  `estado` int(11) NOT NULL,
  `tipo` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `notificaciones`
--

INSERT INTO `notificaciones` (`id_notificacion`, `codigo_usuario`, `codigo_libro`, `descripcion`, `estado`, `tipo`) VALUES
(1, '15121010', 'LI000006', 'Ya esta disponible el libro Matemáticas Financieras tiene la opcion de reservarlo', 1, 'info');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `prestamos`
--

CREATE TABLE `prestamos` (
  `id_prestamos` int(11) NOT NULL,
  `codigo_prestamo` varchar(10) NOT NULL,
  `codigo_libro` varchar(10) NOT NULL,
  `codigo_usuario` varchar(10) NOT NULL,
  `fecha_prestada` varchar(50) NOT NULL,
  `fecha_limite` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `publicaciones`
--

CREATE TABLE `publicaciones` (
  `id_publicacion` int(11) NOT NULL,
  `titulo` varchar(200) NOT NULL,
  `descripcion` longtext NOT NULL,
  `img` varchar(100) NOT NULL,
  `estado` int(11) NOT NULL,
  `fecha_publicada` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `publicaciones`
--

INSERT INTO `publicaciones` (`id_publicacion`, `titulo`, `descripcion`, `img`, `estado`, `fecha_publicada`) VALUES
(1, 'CHhiste', 'jajaja', 'PU000001.jpg', 0, '2017-12-16 01:22:07'),
(2, 'srgundo', 'asdada', 'PU000002.png', 0, '2017-12-16 01:23:22');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reservas`
--

CREATE TABLE `reservas` (
  `id_reserva` int(11) NOT NULL,
  `codigo_reserva` varchar(10) NOT NULL,
  `codigo_libro` varchar(10) DEFAULT NULL,
  `codigo_usuario` varchar(10) DEFAULT NULL,
  `fecha_inicio` varchar(50) DEFAULT NULL,
  `fecha_limite` varchar(50) DEFAULT NULL,
  `lugar_reserva` varchar(10) NOT NULL,
  `estado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `reservas`
--

INSERT INTO `reservas` (`id_reserva`, `codigo_reserva`, `codigo_libro`, `codigo_usuario`, `fecha_inicio`, `fecha_limite`, `lugar_reserva`, `estado`) VALUES
(6, 'RE000001', 'LI000006', '15121041', '2017-12-15 20:31:50', '2017-12-17 20:31:50', 'sala', 1),
(7, 'RE000002', 'LI000003', '15121041', '2017-12-15 20:31:54', '2017-12-17 20:31:54', 'sala', 1),
(8, 'RE000003', 'LI000010', '15121041', '2017-12-15 20:31:59', '2017-12-17 20:31:59', 'sala', 1),
(9, 'RE000004', 'LI000011', '15121041', '2017-12-15 20:32:05', '2017-12-17 20:32:05', 'sala', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuarios`
--

CREATE TABLE `usuarios` (
  `codigo_usuario` varchar(10) NOT NULL,
  `nombre_usuario` varchar(20) DEFAULT NULL,
  `apellido_usuario` varchar(50) DEFAULT NULL,
  `escuela_usuario` varchar(50) NOT NULL,
  `DNI_usuario` int(8) DEFAULT NULL,
  `correo_usuario` varchar(50) DEFAULT NULL,
  `contrasena_usuario` longtext,
  `perfil_usuario` varchar(50) DEFAULT NULL,
  `direccion_usuario` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `usuarios`
--

INSERT INTO `usuarios` (`codigo_usuario`, `nombre_usuario`, `apellido_usuario`, `escuela_usuario`, `DNI_usuario`, `correo_usuario`, `contrasena_usuario`, `perfil_usuario`, `direccion_usuario`) VALUES
('15121010', 'Romario', 'Diaz', 'CONTABILIDAD Y FINANZAS', 0, 'kambacte@gmail.com', '55dc87c474', 'profile.jpg', ''),
('15121041', 'Ciro', 'Yupanqui', 'INGENIERÍA DE SISTEMAS E INFORMÁTICA', 98786564, 'ciriusblb@gmail.com', '2087d58a7079777c3748e002', '15121041face5.png', 'mi casa');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `antiguas_contrasenas`
--
ALTER TABLE `antiguas_contrasenas`
  ADD PRIMARY KEY (`id_antiguo`);

--
-- Indices de la tabla `areas`
--
ALTER TABLE `areas`
  ADD PRIMARY KEY (`codigo_area`);

--
-- Indices de la tabla `comentarios`
--
ALTER TABLE `comentarios`
  ADD PRIMARY KEY (`id_comentario`),
  ADD KEY `codigo_usuario` (`codigo_usuario`),
  ADD KEY `codigo_libro` (`codigo_libro`);

--
-- Indices de la tabla `esperas`
--
ALTER TABLE `esperas`
  ADD PRIMARY KEY (`id_espera`);

--
-- Indices de la tabla `estado_u`
--
ALTER TABLE `estado_u`
  ADD PRIMARY KEY (`id_estado`);

--
-- Indices de la tabla `historial`
--
ALTER TABLE `historial`
  ADD PRIMARY KEY (`id_historial`);

--
-- Indices de la tabla `libros`
--
ALTER TABLE `libros`
  ADD PRIMARY KEY (`id_libro`),
  ADD UNIQUE KEY `codigo_libro` (`codigo_libro`),
  ADD KEY `area_l` (`area_l`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id_notificacion`);

--
-- Indices de la tabla `prestamos`
--
ALTER TABLE `prestamos`
  ADD PRIMARY KEY (`id_prestamos`);

--
-- Indices de la tabla `publicaciones`
--
ALTER TABLE `publicaciones`
  ADD PRIMARY KEY (`id_publicacion`);

--
-- Indices de la tabla `reservas`
--
ALTER TABLE `reservas`
  ADD PRIMARY KEY (`id_reserva`),
  ADD UNIQUE KEY `codigo_reserva` (`codigo_reserva`),
  ADD KEY `id_estado` (`estado`),
  ADD KEY `codigo_usuario` (`codigo_usuario`),
  ADD KEY `codigo_libro` (`codigo_libro`);

--
-- Indices de la tabla `usuarios`
--
ALTER TABLE `usuarios`
  ADD PRIMARY KEY (`codigo_usuario`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `antiguas_contrasenas`
--
ALTER TABLE `antiguas_contrasenas`
  MODIFY `id_antiguo` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `comentarios`
--
ALTER TABLE `comentarios`
  MODIFY `id_comentario` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT de la tabla `esperas`
--
ALTER TABLE `esperas`
  MODIFY `id_espera` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `estado_u`
--
ALTER TABLE `estado_u`
  MODIFY `id_estado` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `historial`
--
ALTER TABLE `historial`
  MODIFY `id_historial` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=121;

--
-- AUTO_INCREMENT de la tabla `libros`
--
ALTER TABLE `libros`
  MODIFY `id_libro` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id_notificacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT de la tabla `prestamos`
--
ALTER TABLE `prestamos`
  MODIFY `id_prestamos` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `publicaciones`
--
ALTER TABLE `publicaciones`
  MODIFY `id_publicacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT de la tabla `reservas`
--
ALTER TABLE `reservas`
  MODIFY `id_reserva` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
