/* validaciones.js - Ayudas de interfaz (complementan, no reemplazan, la validacion del servidor). */
document.addEventListener('DOMContentLoaded', function () {

  // 1) Los campos type="url" deben empezar por http:// o https://
  document.querySelectorAll('input[data-url]').forEach(function (campo) {
    campo.addEventListener('blur', function () {
      var v = campo.value.trim();
      var ok = v === '' || /^https?:\/\/\S+$/i.test(v);
      campo.classList.toggle('is-invalid', !ok);
    });
  });

  // 2) Segunda casilla de pago: aparece solo cuando se escribe el correo del segundo estudiante
  var correo2 = document.getElementById('correo2');
  var caja2 = document.getElementById('caja-pago2');
  var pago2 = document.getElementById('pago2');
  if (correo2 && caja2) {
    var alternar = function () {
      var hay = correo2.value.trim() !== '';
      caja2.classList.toggle('d-none', !hay);
      if (pago2) { pago2.required = hay; }
    };
    correo2.addEventListener('input', alternar);
    alternar();
  }

  // 3) Idea del banco / idea propia: muestra solo el bloque que corresponde
  var modo = document.querySelectorAll('input[name="modo_idea"]');
  var bloqueBanco = document.getElementById('bloque-banco');
  var bloquePropia = document.getElementById('bloque-propia');
  if (modo.length && bloqueBanco && bloquePropia) {
    var cambiar = function () {
      var propia = document.querySelector('input[name="modo_idea"]:checked').value === 'propia';
      bloqueBanco.classList.toggle('d-none', propia);
      bloquePropia.classList.toggle('d-none', !propia);
    };
    modo.forEach(function (m) { m.addEventListener('change', cambiar); });
    cambiar();
  }

  // 4) Confirmacion antes de acciones delicadas
  document.querySelectorAll('[data-confirmar]').forEach(function (el) {
    el.addEventListener('click', function (ev) {
      if (!window.confirm(el.getAttribute('data-confirmar'))) { ev.preventDefault(); }
    });
  });
});
