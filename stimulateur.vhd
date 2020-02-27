
------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use work.all;

package stimul_pack is
    
 type etat_signal is (signal_zero, signal_chirp, signal_bruit, signal_chirp_bruit);   
 
 -- Declaration de Constantes
constant retard : integer ;
constant recurrence : integer ;
constant teta : integer ;
constant fin : integer;

end stimul_pack;

package body stimul_pack is  
    
constant retard : integer :=100;
constant recurrence : integer :=255;
constant teta : integer := 44;
constant fin : integer:=299;

end stimul_pack;
--*********************************************************************************
--		COMPTEUR DU SEQUENCEUR
--**********************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;



entity compt_seq_stim is
  
  port(	
  
  reset, clke, count_enable : in std_logic;
	s_44, s_100, s_144, s_255, s_299 : out std_logic
	
	);
end compt_seq_stim;



architecture arch_compt_seq_stim of compt_seq_stim is	
	
	signal compteur : integer range 0 to 299;
	
	begin
	  
	  process(clke, reset)
	    
	    begin
	      
	      if reset='0' then 
	      
	         if rising_edge(clke) then
	        
	           if count_enable = '1' then
	        
	           if compteur =299 then compteur <= 0; else compteur <= compteur+1; end if;
	           end if;
	          end if;
	      
	      else compteur <= 0;
	      end if;
	
  end process;
  
  s_44 <= '1' when compteur=45  else '0';
  s_100<= '1' when compteur=100 else '0';
  s_144<= '1' when compteur=145 else '0'; 
  s_255<= '1' when compteur=255 else '0';
  s_299<= '1' when compteur=299 else '0';
  
end arch_compt_seq_stim;






--*********************************************************************************
--		GENERATEUR DE BRUIT
--*********************************************************************************


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;



entity gene_bruit is
   
port(
	clke : in std_logic;
	bruit : out std_logic_vector(7 downto 0)
);
end gene_bruit;

architecture arch_gene_bruit of gene_bruit is

begin
   process(clke)
       variable s1 : integer :=1233;
       variable s2 : integer := 4798;
       variable v_bruit : real :=0.0;

       
   begin    
         if(rising_edge(clke))
               	then uniform(s1, s2, v_bruit);
		               v_bruit:=0.999*(v_bruit - 0.5);
		               
-- conversion real -> std_logic_vector sur 8 bit en virgule fixe 1.7
bruit <= std_logic_vector(to_signed(integer(round(128.0*v_bruit)),8));
         end if; 
end process;
end arch_gene_bruit;





--*********************************************************************************
--		GENERATEUR DE CHIRP
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.stimul_pack.all;
use work.all;

entity gene_chirp is
port(
	clke : in std_logic;
	choix : in etat_signal;
	inc_delta_f : in std_logic;
	raz_delta_f : in std_logic;
	chirp : out std_logic_vector(7 downto 0)

);
end gene_chirp;

architecture arch_gene_chirp of gene_chirp is


	signal delta_f, chirp_interne : real;

	function f_chirp(n_ech:real ; delta_f : real) return real is
	variable phase : real :=0.0;
	begin
	phase:=((math_pi*delta_f)*((n_ech*n_ech/44.0) - n_ech));
	return 0.499*cos(phase);
	end f_chirp;
	
	

begin

process(clke)
variable numero_ech : real;
variable compt_delta_f : real;
begin

if(rising_edge(clke)) then


if(raz_delta_f='1') then delta_f <= 0.0; compt_delta_f:=0.0;-- attention initialisation 
elsif (inc_delta_f = '1') then      compt_delta_f := compt_delta_f + 1.0;
                                    delta_f<= (compt_delta_f mod 12.0)*0.05;

end if;

	if (choix=signal_chirp or choix=signal_chirp_bruit) then

							chirp_interne<= f_chirp(numero_ech, delta_f); 
							numero_ech := numero_ech + 1.0;

							else numero_ech := 0.0;
							     chirp_interne<=0.0;

	end if;
end if;

end process;
chirp <= std_logic_vector(to_signed(integer(round(128.0*chirp_interne)),8));
end arch_gene_chirp;


--*********************************************************************************
--		Multiplexeur
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.stimul_pack.all;


entity multiplexeur is
port(
	bruit, chirp : in std_logic_vector(7 downto 0);
	choix : in etat_signal;
	d_out : out std_logic_vector(7 downto 0)

);
end multiplexeur;

architecture arch_multiplexeur of multiplexeur is

signal d_out_real : real:=0.0;


begin

with choix select

	d_out <= bruit 		         when signal_bruit,
		       chirp 		         when signal_chirp,
		       std_logic_vector( signed(chirp) +signed (bruit)) when signal_chirp_bruit,
		       "00000000" 		     when others;		
 

-- Conversion flottant vers représentation 0.7

end arch_multiplexeur;







--*********************************************************************************
--		SEQUENCEUR
--*********************************************************************************
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.stimul_pack.all;


entity stim_sequenceur is
port(
	reset : in std_logic;
	clke : in std_logic;
  s_44, s_100, s_144, s_255, s_299 : in std_logic;
  count_enable : out std_logic;
  
	raz_delta_f : out std_logic;

	inc_delta_f: out std_logic;
	raz_echantillon : out std_logic;

	choix : out etat_signal;

	ref : out std_logic
);
end stim_sequenceur;

architecture arch_stim_sequenceur of stim_sequenceur is

type etats is (repos, initialisation_1, chirp_ref, zero_1, reception,  zero_2, pause_1, initialisation_2, bruit_1, reception_bruit, bruit_2, pause_2);
signal etat_cr, etat_sv : etats;


begin
  
etat_cr <= repos when reset ='1' else
		      etat_sv when rising_edge(clke) else
		      etat_cr;  



process(etat_cr,s_44, s_100, s_144, s_255, s_299)

begin

inc_delta_f <= '0';
raz_delta_f <= '0';
inc_delta_f <= '0';
raz_echantillon <= '0';
choix <= signal_zero;
ref <= '0';
count_enable <= '0';

etat_sv <=etat_cr ;


case etat_cr is

	when repos 		=>	etat_sv <= initialisation_1;
	  
	raz_delta_f <='1';
	raz_echantillon <='1';

	when initialisation_1	=>	etat_sv <= chirp_ref;
	                         choix <= signal_chirp; -- sortie Mealy
	
	inc_delta_f <='1';
	raz_echantillon <='1' ;
	count_enable <= '1';
	

	when chirp_ref		=>	if s_44='1' then etat_sv <= zero_1; else etat_sv <= chirp_ref; end if;  
	choix <= signal_chirp;
	ref <='1';
	count_enable <= '1';

	when zero_1		=>	if s_100='1' then etat_sv <= reception;
                                    choix <= signal_chirp; -- sortie Mealy
	                else etat_sv <= zero_1; end if;
	count_enable <= '1'; 
	
	when reception		=>	if s_144='1' then etat_sv <= zero_2; else etat_sv <= reception; end if;  
	choix <= signal_chirp;
	count_enable <= '1';

	when  zero_2		=>	if s_255='1' then etat_sv <= pause_1; else etat_sv <= zero_2; end if;
  count_enable <= '1';
  
	when pause_1		=>	if s_299='1' then etat_sv <= initialisation_2; else etat_sv <= pause_1; end if;
  count_enable <= '1';

	when initialisation_2	=> etat_sv <= bruit_1;  
	raz_echantillon <='1';
	count_enable <= '1';

	when bruit_1		=>	if s_44='1' then etat_sv <= reception_bruit; else etat_sv <= bruit_1; end if;  
	choix <= signal_bruit;
	count_enable <= '1';

	when reception_bruit	=>	if s_144='1' then etat_sv <= bruit_2; else etat_sv <= reception_bruit;
	                                                                   choix <= signal_chirp; -- sortie Mealy
	                                                                    end if;  
	choix <= signal_chirp_bruit;
	count_enable <= '1';

	when bruit_2		=>	if s_255='1' then etat_sv <= pause_2; else etat_sv <= bruit_2; end if;  
	choix <= signal_bruit;
	count_enable <= '1';

	when pause_2		=>	if s_299='1' then etat_sv <= initialisation_1; else etat_sv <= pause_2; end if;
  count_enable <= '1';

end case;
end process;


end arch_stim_sequenceur;









--*********************************************************************************
--*********************************************************************************
--				STIMULATEUR
--*********************************************************************************
--*********************************************************************************

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.stimul_pack.all;
use work.all;


entity stimulateur is
port(

reset : in std_logic;
clke : in std_logic;
d_out : out std_logic_vector(7 downto 0);
ref : out std_logic

);
end stimulateur;

architecture arch_stimulateur of stimulateur is


signal chirp : std_logic_vector(7 downto 0);
signal bruit : std_logic_vector(7 downto 0);
signal  raz_delta, raz_ech, s_44, s_100, s_144, s_255, s_299, inc_delta_f, count_enable : std_logic;
signal choix : etat_signal;

begin

compt:      entity compt_seq_stim port map (  reset  => reset,
                                            clke => clke, 
                                            count_enable => count_enable,
                                        	   s_44=> s_44,
                                          	 s_100=> s_100, 
                                            s_144=> s_144,
                                            s_255=> s_255, 
                                            s_299 => s_299 );
                                              
stim_seq:        entity stim_sequenceur port map (reset => reset, 
                                        clke => clke,
                                        s_44=> s_44, 
                                        s_100 => s_100, 
                                        s_144 => s_144, 
                                        s_255 => s_255, 
                                        s_299 => s_299,
                                        count_enable => count_enable, 
                                        inc_delta_f => inc_delta_f,
                                        raz_delta_f => raz_delta, 
                                        raz_echantillon => raz_ech,
                                        choix => choix, 
                                        ref => ref);
                                        
mux :       entity multiplexeur port map(bruit => bruit, 
                                        chirp => chirp, 
                                        choix => choix, 
                                        d_out => d_out);
                                        
gen_bruit : entity gene_bruit port map(clke => clke , 
                                       bruit => bruit);
                                       
gen_chirp : entity gene_chirp port map( clke => clke, 
                                        choix=> choix, 
                                        inc_delta_f => inc_delta_f, 
                                        raz_delta_f => raz_delta, 
                                        chirp => chirp);

end arch_stimulateur;



