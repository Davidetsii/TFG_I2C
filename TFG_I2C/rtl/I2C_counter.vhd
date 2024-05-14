
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity I2C_counter is
    generic (
                C_FREQ_SYS   : integer := 100000000;    -- 100 MHz
                C_FREQ_I2C   : integer := 100000       -- 100 KHz en SCL    
    );
    Port ( 
            -- ENTRADAS
            clk     : in std_logic;
            reset_n : in std_logic;
            stop    : in std_logic;
            stop_count  : in std_logic;
            condition   : in std_logic;
            done        : in std_logic;
            -- SALIDAS
            overflow: out std_logic;
            scl     : inout std_logic;
            div     : out std_logic_vector(1 downto 0)
    );
end I2C_counter;
    

architecture Behavioral of I2C_counter is

    signal clr_cont     : std_logic;
    constant MAX_CNT    : integer := (C_FREQ_SYS/C_FREQ_I2C)/4;     -- 500 KHz
    signal cont         : integer range (C_FREQ_SYS/C_FREQ_I2C)/4 - 1 downto 0;
    signal cont_4       : unsigned(1 downto 0);

begin

    -- CONTADOR 500 KHz
    cont_500KHz : process (clk,reset_n)
    begin
        if reset_n = '0' then
            cont <= 0;
        elsif clk'event and clk = '1' then
            if stop_count = '1' then
                cont <= 0;
            else
                if cont = (C_FREQ_SYS/C_FREQ_I2C)/4 - 1 then
                    cont <= 0;
                else
                    cont <= cont + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- CONTADOR 1 a 4
    cont_1a4: process (clk,reset_n)
    begin
        if reset_n = '0' then
            cont_4 <= (others => '0');
        elsif clk'event and clk = '1' then
            if stop_count = '1' then
                cont_4 <= (others => '0');
            else
                if cont = (C_FREQ_SYS/C_FREQ_I2C)/4 - 1 then
                    if cont_4 = "11" or (condition = '1' and cont_4 = "01")then
                        cont_4 <= (others => '0');
                    else
                        cont_4 <= cont_4 + 1;
                    end if;
                end if;     
            end if;
        end if;
    end process;    
    
    
    -- GENERACI�N SCL
  --  SCL_OUT: process (clk,reset)
  --  begin
       -- if reset = '1' then
     --       SCL <= '1';
   --     elsif clk'event and clk = '1' then
        --    if clr_cont = '1' then
      --          SCL <= '1';
    --        else
               -- if cont_4(1) = '0' then
             --       SCL <= '0';
           --     elsif cont_4(1) = '1' then
         --           SCL <= '1';
       --         end if;     
     --       end if;
   --     end if;
   -- end process;    
   scl <= '0' when (cont_4(1) = '0' and reset_n = '1' and clr_cont = '0') or (condition = '1' and done = '1') else '1';
    
    -- Reset s�ncrono del SCL
    clr_cont <= stop_count or stop;
    
    -- SALIDA DIV
    div     <= std_logic_vector(cont_4);  
    
    -- SALIDA EN FORMA DE DESBORDAMIENTO
    overflow <= '1' when cont = (C_FREQ_SYS/C_FREQ_I2C)/4 - 1 else '0';

end Behavioral;
