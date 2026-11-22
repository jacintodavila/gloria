# Agente `centinela` — Ciberseguridad y Mitigación Abductiva

Agente reactivo dirigido por objetivos desarrollado para **GLORIA** que modela la detección y respuesta proporcional ante incidentes de seguridad informática a lo largo del tiempo ($T = 0, 1, 2, \dots$).

## Archivos
- `centinela.main`: Declaración de predicados abducibles (`abd/1`) y observables (`observable/1`).
- `centinela.kb`: Metas reactivas (`if_/2`) y creencias de mitigación (`def/2`).

## Reglas del Dominio
1. **Falso positivo en mantenimiento:** Ante `intentos_fallidos(IP)` o `trafico_anomalo(IP)` desde `ip_interna(IP)` durante `ventana_mantenimiento`, evita el bloqueo y solo registra auditoría (`registrar_auditoria(IP)`).
2. **Actividad interna sospechosa:** Ante anomalías desde `ip_interna(IP)` en `operacion_normal`, solicita doble factor (`solicitar_2fa(IP)`) y audita (`registrar_auditoria(IP)`).
3. **Ataque externo:** Ante anomalías desde `ip_externa(IP)`, bloquea la dirección (`bloquear_ip(IP)`) y escala alerta al equipo de seguridad (`levantar_alerta_soc(IP)`).
4. **Contención y recuperación temporal de malware:** Ante `hash_malicioso(Host)`, aísla el equipo (`aislar_host(Host)`) y alerta al SOC inmediatamente (incluso en ventana de mantenimiento). Cuando en un paso posterior se observa `parche_aplicado(Host)`, ejecuta `restaurar_host(Host)`.

## Casos de Prueba Verificados (`gloria_run_step`)

| Escenario | Observaciones de Entrada | Acciones Generadas |
| :--- | :--- | :--- |
| **1. Operación normal** | `[ip_interna('192.168.1.10'), operacion_normal]` | `[]` |
| **2. Falso positivo (mantenimiento)** | `[intentos_fallidos('192.168.1.50'), ip_interna('192.168.1.50'), ventana_mantenimiento]` | `[do(registrar_auditoria('192.168.1.50'), 0)]` |
| **3. Sospecha interna** | `[intentos_fallidos('192.168.1.25'), ip_interna('192.168.1.25'), operacion_normal]` | `[do(solicitar_2fa('192.168.1.25'), 0), do(registrar_auditoria('192.168.1.25'), 0)]` |
| **4. Ataque externo** | `[intentos_fallidos('203.0.113.42'), ip_externa('203.0.113.42')]` | `[do(bloquear_ip('203.0.113.42'), 0), do(levantar_alerta_soc('203.0.113.42'), 0)]` |
| **5a. Malware crítico ($T=0$)** | `[hash_malicioso('srv_bd_01'), ventana_mantenimiento]` | `[do(aislar_host(srv_bd_01), 0), do(levantar_alerta_soc(srv_bd_01), 0)]` |
| **5b. Recuperación tras parche ($T=1$)** | `[parche_aplicado('srv_bd_01')]` | `[do(restaurar_host(srv_bd_01), 1)]` |
