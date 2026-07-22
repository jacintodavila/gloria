TITLE
    Sistema simple de taquillas con gerente y clientes que se quejan
    Éste es un Ejemplo de Simulacion MultiAgente
NETWORK
    Entrada(I){
        IT(10);
        SENDTO(MIN(Taquilla));
    }
    Taquilla[3] (R) {
        RELEASE
            SENDTO(Salida);
        STAY(45);
    }
    Salida (E){}

INIT
    TSIM = 300;
    ACT(Entrada,0);
DECL
    MESSAGES Entrada(CerebroCliente cerebroCliente);
    STATISTICS ALLNODES;
END.

AGENTS {
    Gerente {
    
    	Prolog {
    	
	        abd(cola_larga).
        	abd(crear_taquilla).
        	abd(taq_vacias).
        	abd(elim_taquilla).
        	abd(revisa_cola).
        	observable(cola_larga).
        	observable(taq_vacias).
		user_built(timing(_)). 
		
		timing(T) :- gensym('', C), atom_number(C, T).
	}
	
	Goals {

	        if timing(T)  then revisa_cola(T).
        	if cola_larga then crear_taquilla.
        	if taq_vacias then elim_taquilla.
        	
        }
	
    }

    CerebroCliente{
    
    	Prolog { 
	        abd(queja_gerente).
        	abd(revisa_tiempo).
        	observable(mucho_tiempo_espera).
        	abd(cola_larga).
        	user_built(timing(_)). 
        	
		timing(T) :- gensym('', C), atom_number(C, T).
        
		
	}
	Goals { 
        	if timing(T) then revisa_tiempo(T).
        	if mucho_tiempo_espera then queja_gerente.
        }

    }
}
INTERFACE
// La convención para la traducción podría ser la siguiente:
// Existe una clase principal del modelo guardada en su
// propio archivo .java. El traductor usará el nombre del 
// archivo .g para nombrar esta clase. En este caso es Taquilla3.
// El programador de la interfaz tendrá acceso a la clase 
// principal usando ese identificador. 
//
// En la clase principal se declararán los objetos que representan
// a los nodos de la red, usando el mismo nodo que los define en
// la sección NETWORK del archivo .g, pero escrito completamente en
// minúsculas. En este caso, Taquilla da origen a taquilla, 
// Entrada a entrada y Salida a objeto salida de ese tipo. 
// taquilla será, inicialmente, un arreglo Java de 3 elementos
// debido a la capacidad declarada con Taquilla (R) [3]. 

// todo método de la interfaz debe tener como primeros dos argumentos
// a double t, Gerente agente, de manera que el usuario pueda 
// referirse al tiempo actual, con t, y al agente involucrado, con 
// agente (otros nombres de variable son posibles. Lo importante es
// que sean del tipo correcto). 

// Los restantes argumentos, si los hubiere, deben corresponder a
// tipos válidos en la biblioteca jpl. (listar cuáles).

// Desde la interfaz, el usuario tiene acceso a todos los métodos del
// nivel Java de las bibliotecas de Galatea. 

 public void revisa_cola(double t, Gerente agente, jpl.Integer at) {
        int clientes_en_banco = 0;
        for (int i = 0; i <  Taquilla3.taquilla.length; i++) {
            clientes_en_banco =+ Taquilla3.taquilla[i].getEl().ll();
        }

        if (clientes_en_banco > 10) {
            agente.inputs.add("cola_larga");        }
    }

    public void queja(double t, Gerente agente) {
        System.err.println("#"+agente.agentType+agente.agentId + ": Cola larga!!");
    }

    public void crear_taquilla(double t, Gerente agente) {
        if (Taquilla.mult > Taquilla.maxMult) {
            System.out.println("Banco lleno!!");
        } else {
            Taquilla3.addInstance();
        }
    }

    public void taq_vacias(double t, Gerente agente) {
        for (int i = 0, j = 0; i < Taquilla.mult; i++) {
            if (Taquilla3.taquilla[i].getEl().ll() + Taquilla3.taquilla[i].getIl().ll() == 0) {
                j++;
                if (j > 1) {
                    agente.inputs.add("taq_vacias");
                }
            }
        }
    }

    public void elim_taquilla(double t, Gerente agente) {
        int i = 0;
        while ((i < Taquilla.mult - 1) &
                (Taquilla3.taquilla[i].getIl().ll() + Taquilla3.taquilla[i].getEl().ll() > 0)) {
            i++;
        }
        if (Taquilla3.taquilla[i].getIl().ll() + Taquilla3.taquilla[i].getEl().ll() == 0) {
            Taquilla3.delInstance(i);timing(T) :- gensym('', C), atom_number(C, T).
        }
    }
