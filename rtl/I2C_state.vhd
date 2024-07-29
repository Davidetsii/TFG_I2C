library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity I2C_state is
    Port ( 
            clk         : in std_logic;
            reset_n     : in std_logic;
            start       : in std_logic; -- ON = '1', OFF = '0' 
            r_w_inter   : out std_logic;-- WRITE = '0', READ = '1'
            overflow    : in std_logic;
            div         : in std_logic_vector(1 downto 0);
            sda_in      : in std_logic;
            done        : out std_logic;
            done_aux    : out std_logic;
            stop_count  : out std_logic;
            stop_scl    : out std_logic;
            sipo        : out std_logic;
            piso        : out std_logic;
            ack_s       : out std_logic;
            stop_sda    : out std_logic;
            zero_sda    : out std_logic;
            reading     : out std_logic;
            condition   : out std_logic;
            operation   : in std_logic 
    );
end I2C_state;

architecture Behavioral of I2C_state is

    type machine is (IDLE, STARTING, ZERO, SEND, RECEIVE, ACK, RESTART, PRESTOP, STOP);
    signal FSM, FSM_ant  : machine;
    signal final_scl, stop_scl_aux, stop_count_aux, save, final_count, s_ack, R_W_aux : std_logic;
    signal cont, cont_restart : unsigned (2 downto 0);
    signal byte_w   : integer range 0 to 4;
    signal byte_r   : integer range 0 to 3;
    signal cont_zero: unsigned(1 downto 0);
    signal BYTES_W  : std_logic_vector(1 downto 0) := "01";
    signal BYTES_R  : std_logic_vector(1 downto 0);
    signal sda_reg, sda_s : std_logic;
    
begin

    -- Synchronizer for SDA
    process (clk, reset_n)
    begin
        if reset_n = '0' then
            sda_reg <= '0';
            sda_s   <= '0';
        elsif clk'event and clk = '1' then
            sda_reg <= sda_in;
            sda_s   <= sda_reg;
        end if;
    end process;

    --FSM
    process(clk,reset_n)
    begin
        if reset_n = '0' then
            FSM <= IDLE;
            FSM_ant <= IDLE;
            cont_restart <= "000";
            cont_zero <= "00";
            stop_count_aux <= '1';
            stop_scl_aux <= '1';
            sipo        <= '0';
            piso        <= '0';
            s_ack       <= '0';
            stop_sda    <= '1';
            zero_sda    <= '0';
            byte_w      <= 0;
            byte_r      <= 0;
            cont <= (others => '0');
            done <= '0';
            done_aux <= '0';
            condition <= '0';
            R_W_aux <= '0';
        elsif clk'event and clk = '1' then
                if FSM = IDLE then
                    cont_restart <= "000";
                    stop_count_aux <= '1';
                    stop_scl_aux <= '1';
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '1';
                    zero_sda    <= '0';
                    byte_w      <= 0;
                    byte_r      <= 0; 
                    cont <= (others => '0');
                    if FSM_ant = IDLE then                    
                        done <= '0';
                        done_aux <= '0';
                    elsif FSM_ant = STOP then
                        done <= '1';
                        done_aux <= '1';
                    end if;   
                    condition <= '0'; 
                    R_W_aux <= '0';               
                    if start = '1' then
                        FSM <= STARTING;
                    end if;
                elsif FSM = STARTING then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1';  
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '1';
                    cont <= (others => '0');
                    done <= '0';
                    done_aux <= '0';
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        FSM <= ZERO;
                        FSM_ant <= STARTING;
                    end if;
                elsif FSM = SEND then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '0';
                    piso        <= '1';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '0';
                    done <= '0';
                    done_aux <= '0';
                    condition <= '0';
                    if final_scl = '1' then
                        if cont = "111" then
                            FSM <= ACK;
                        else
                            cont <= cont + 1;
                        end if;
                    end if;  
                elsif FSM = ACK then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '1';
                    piso        <= '0';
                    s_ack       <= '1';
                    cont <= (others => '0');
                    done <= '0';   
                    done_aux <= '0';     
                    condition <= '0';   
                    if byte_r = to_integer(unsigned(BYTES_R)) and R_W_aux = '1' then
                        stop_sda    <= '1';
                        zero_sda    <= '0';                         
                    else
                        stop_sda    <= '0';
                        zero_sda    <= '1';                     
                    end if;
                    if final_scl = '1' then
                        FSM <= ZERO;
                        if sda_s = '1' or sda_s = 'H' then
                            FSM_ant <= ZERO;
                        elsif FSM_ant = RECEIVE then
                            FSM_ant <= RECEIVE;
                        elsif FSM_ant <= IDLE then
                            FSM_ant <= IDLE;
                        else
                            FSM_ant <= ACK;
                        end if;
                    end if;           

                elsif FSM = RECEIVE then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0';
                    sipo        <= '1';
                    piso        <= '0';
                    s_ack       <= '0';
                    zero_sda    <= '0';  
                    done <= '0'; 
                    done_aux <= '0';    
                    condition <= '0';           
                    if final_scl = '1' then
                        if cont = "111" then
                            FSM <= ACK;
                            FSM_ant <= RECEIVE;
                            if byte_r = to_integer(unsigned(BYTES_R)) then
                                byte_r      <= byte_r + 1;
                                stop_sda    <= '1';
                            else
                                byte_r      <= byte_r + 1;
                                stop_sda    <= '0';
                            end if;
                        else
                            cont <= cont + 1;  
                            stop_sda    <= '0';
                        end if; 
                    end if;   
                
                elsif FSM = RESTART then
                    stop_count_aux <= '0';    
                    sipo        <= '1';
                    piso        <= '0';
                    s_ack       <= '0';  
                    done <= '0';  
                    done_aux <= '0';
                       
                    if (overflow = '1' and div = "01") then
                        if cont_restart = "011" then
                            FSM <= ZERO;
                            FSM_ant <= RESTART;
                            R_W_aux <= '1';
                            condition <= '0'; 
                        elsif cont_restart = "010" then
                            cont_restart <= cont_restart + 1;
                            condition <= '0'; 
                            stop_scl_aux <= '1';  
                            stop_sda    <= '0';
                            zero_sda    <= '1';   
                        elsif cont_restart = "001" then
                            cont_restart <= cont_restart + 1;    
                            condition <= '0';    
                            stop_scl_aux <= '1';                   
                        elsif cont_restart = "000" then
                            cont_restart <= cont_restart + 1;
                            stop_sda    <= '1';
                            zero_sda    <= '0';
                            stop_scl_aux <= '0';  
                            condition <= '1';                                      
                        end if;
                    end if;                                      

                elsif FSM = ZERO then    
                    stop_count_aux <= '0';
                    stop_scl_aux <= '0'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    cont <= (others => '0');
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        if FSM_ant = STARTING or FSM_ant = RESTART then
                            stop_sda    <= '0';
                            zero_sda    <= '1';
                            FSM <= SEND;
                            if FSM_ant = STARTING then
                                FSM_ant <= ZERO;  
                            else
                                FSM_ant <= IDLE;      
                            end if;
                            done <= '0';
                            done_aux <= '0';
                            byte_w <= byte_w + 1;
                        else
                            if cont_zero = "11" then
                                cont_zero <= "00";
                                if FSM_ant = ACK then
                                    if byte_w = to_integer(unsigned(BYTES_W)) + 1 then
                                        if BYTES_R = "00" then
                                            FSM <= PRESTOP;
                                            FSM_ant <= ZERO; 
                                            stop_sda    <= '0';
                                            zero_sda    <= '1';
                                        else
                                            FSM <= RESTART;
                                            FSM_ant <= ZERO;
                                            stop_sda    <= '1';
                                            zero_sda    <= '0';
                                        end if; 
                                    else
                                        byte_w <= byte_w + 1;
                                        FSM <= SEND;
                                        FSM_ant <= ZERO;
                                        stop_sda    <= '0';
                                        zero_sda    <= '1';                                          
                                    end if;
                                elsif FSM_ant = ZERO then
                                        FSM <= PRESTOP;
                                        FSM_ant <= ZERO; 
                                        stop_sda    <= '0';
                                        zero_sda    <= '1';  
                                elsif FSM_ant = IDLE then
                                    FSM <= RECEIVE;
                                    FSM_ant <= ZERO;    
                                    stop_sda    <= '0';
                                    zero_sda    <= '1';  
                                elsif FSM_ant = RECEIVE then
                                    if byte_r = to_integer(unsigned(BYTES_R)) then
                                        FSM <= PRESTOP;
                                        FSM_ant <= ZERO;
                                        stop_sda    <= '0';
                                        zero_sda    <= '0';
                                    else
                                        FSM <= RECEIVE;                                 
                                    end if;                            
                                end if;                              
                            else
                                cont_zero <= cont_zero + 1;
                                stop_sda    <= '0';
                                zero_sda    <= '1';
                            end if;                                                                               
                        end if;
                    end if;                   
                elsif FSM = PRESTOP then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '0';
                    zero_sda    <= '1';
                    cont <= (others => '0');
                    done <= '1';
                    done_aux <= '1';
                    condition <= '1';
                    if (overflow = '1' and div = "01") then
                        FSM <= STOP;
                        FSM_ant <= PRESTOP;
                    end if;                                                                                             
                elsif FSM = STOP then
                    stop_count_aux <= '0';
                    stop_scl_aux <= '1'; 
                    sipo        <= '0';
                    piso        <= '0';
                    s_ack       <= '0';
                    stop_sda    <= '1';
                    zero_sda    <= '0';
                    cont <= (others => '0');
                    done <= '1';
                    done_aux <= '1';
                    condition <= '0';
                    if final_scl = '1' then
                        FSM <= IDLE;
                        FSM_ant <= STOP;
                    end if;                                                                                            
                end if;                            
            end if;
    end process;
    
    ack_s <= s_ack;
    r_w_inter <= R_W_aux;
    final_count <= '1' when (final_scl = '1' and  stop_scl_aux = '1') and cont = "111" else '0';
    final_scl <= '1' when (overflow = '1' and div = "11") else '0';
    stop_scl <= stop_scl_aux;
    stop_count <= stop_count_aux;
    reading <= '1' when (FSM = ACK and FSM_ant /= RECEIVE) or (FSM = RECEIVE) else '0';
    save <= '1' when (overflow = '1' and div = "00") else '0';
    BYTES_R <= "10" when operation = '1' else "00";
    
    
end Behavioral;

