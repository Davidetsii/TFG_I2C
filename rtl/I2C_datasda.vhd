library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity I2C_datasda is
    Port ( 
            clk         : in std_logic;
            reset_n     : in std_logic; 
            overflow    : in std_logic;
            div         : in std_logic_vector(1 downto 0);                
            sipo        : in std_logic;
            piso        : in std_logic;
            ack_s       : in std_logic;
            r_w         : in std_logic;
            done        : in std_logic;
            stop_sda    : in std_logic;
            zero_sda    : in std_logic;
            reading     : in std_logic;
            address     : in std_logic_vector(6 downto 0);
            data_in     : in std_logic_vector(7 downto 0);
            sda_in      : in std_logic;
            sda_out     : out std_logic;
            sda_en      : out std_logic;
            data_read   : out std_logic_vector(15 downto 0)       
    );
end I2C_datasda;

architecture Behavioral of I2C_datasda is
    
    signal save, final_scl, read_aux, sda_en_aux  : std_logic;
    signal aux  : std_logic_vector(15 downto 0);
    signal data_out : std_logic_vector(15 downto 0);
    
begin

    -- REGISTROS CON DESPLAZAMIENTO (PISO, SIPO) Y CONTROL DEL SDA EN ACK
    process(clk,reset_n)
    begin
        if reset_n = '0' then
            aux <= address & r_w & data_in;
            data_out <= (others => '0');
        elsif clk'event and clk = '1' then
            if stop_sda = '1' or (zero_sda = '1' and r_w = '1') then
                aux <= address & r_w & data_in;
            elsif ack_s = '1' then
                aux(15 downto 8) <= data_in;
            elsif final_scl = '1' then
                if piso = '1' then
                    if ack_s = '1' then
                        if done = '1' then
                            aux(15) <= '1';
                        else
                            aux(15) <= '0';
                        end if;    
                    else
                        -- PARTE PISO
                        aux <= aux(14 downto 0) & aux(15);
                    end if;
                end if;
                if sipo = '1' then
                    if ack_s = '1' then
                    else
                        -- PARTE SIPO
                        data_out <= data_out(14 downto 0) & sda_in;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- SDA
    process(clk,reset_n)
    begin
        if reset_n = '0' then
            sda_en_aux <= '1';
        elsif clk'event and clk = '1' then
                if ack_s = '1' and stop_sda = '1' then
                    sda_en_aux <= '1';
                elsif save = '1' then
                    if ack_s = '1' then
                        if done = '1' then
                            sda_en_aux <= '1';
                        else
                        sda_en_aux <= '0';
                        end if;
                    elsif stop_sda = '1' then
                        sda_en_aux <= '1';
                    elsif zero_sda = '1' then
                        sda_en_aux <= '0';
                    else
                        sda_en_aux <= aux(15);
                    end if; 
                else
                        if save = '1' then
                            sda_en_aux <= stop_sda; 
                        end if;                        
                end if;         
        end if;
    end process;
    
    --AJUSTE DEL CICLO SDA PARA CORRECTO FUNCIONAMIENTO
    process(clk,reset_n)
    begin
        if reset_n = '0' then
            read_aux <= '0';
        elsif clk'event and clk = '1' then
            if save = '1' then
            read_aux <= reading;
            end if;
        end if;
    end process;
    
    data_read <= data_out when done = '1' else (others => '0');
    sda_out <= '0';
    sda_en  <= '0' when sda_en_aux = '0' and read_aux = '0' else '1';
    --sda <= 'Z' when read_aux = '1' else sda_out;
    save <= '1' when (overflow = '1' and div = "00") else '0';
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';

end Behavioral;
