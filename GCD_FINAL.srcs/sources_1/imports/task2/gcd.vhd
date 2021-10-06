-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2019 v.5.0
--
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port (clk : in std_logic;             -- The clock signal.
    reset : in  std_logic;              -- Reset the module.
    req   : in  std_logic;              -- Input operand / start computation.
    AB    : in  unsigned(15 downto 0);  -- The two operands.
    ack   : out std_logic;              -- Computation is complete.
    s_blue  : out std_logic;            -- last input received / computation is complete.
    s_green : out std_logic;            -- last input received / computation is complete.
    s_red   : out std_logic;            -- last input received / computation is complete.
    C     : out unsigned(15 downto 0)); -- The result.
end gcd;

architecture fsmd of gcd is

  type state_type is (s_init, s_input_A, s_input_A_read, s_input_idle, s_input_B, s_input_B_read, s_input2_idle, s_compare, s_a_gt_b, s_a_lt_b, s_found, s9, s10, s11); -- Input your own state names

  signal reg_a, next_reg_a, next_reg_b, reg_b : unsigned(15 downto 0) := (others => '0');

  signal state, next_state : state_type := s_init;


begin

  -- Combinatoriel logic

  cl : process (req,ab,state,reg_a,reg_b,reset)
  begin

    case (state) is

        when s_init =>
            s_blue <= '0';
            s_green <= '1';
            s_red <= '0';
            ack <= '0';
            if req = '1' then
                s_blue <= '0';
                s_green <= '0';
                s_red <= '0';
                next_state <= s_input_A;
            end if;
        when s_input_A => 
            s_blue <= '1';
            s_green <= '0';
            s_red <= '0';
            next_reg_a <= AB;
            next_state <= s_input_A_read;
        when s_input_A_read =>
            s_blue <= '0';
            s_green <= '1';
            s_red <= '0';
            ack <= '1';
            if req = '0' then
                next_state <= s_input_idle;
            end if;
        when s_input_idle =>
            s_blue <= '0';
            s_green <= '0';
            s_red <= '1';
            ack <= '0';
            if req = '1' then
                next_state <= s_input_B;
            end if;
        when s_input_B => 
            s_blue <= '1';
            s_green <= '0';
            s_red <= '0';
            next_reg_b <= AB;
            next_state <= s_input_B_read;
        when s_input_B_read => 
            s_blue <= '0';
            s_green <= '1';
            s_red <= '0';
            --ack <= '1';
            --if req = '0' then
            next_state <= s_input2_idle;
            --end if;
        when s_input2_idle =>
            s_green <= '1';
            ack <= '0';
            next_state <= s_compare;
        when s_compare => 
            s_red <= '1';
            if (reg_a > reg_b) then
                next_state <= s_a_gt_b;
            elsif (reg_a < reg_b) then
                next_state <= s_a_lt_b;
            else
                next_state <= s_found;
            end if;
        when s_a_gt_b => 
            next_reg_a <= reg_a - reg_b;
            next_state <= s_compare;
        when s_a_lt_b => 
            next_reg_b <= reg_b - reg_a;
            next_state <= s_compare;
        when s_found => 
            --C <= reg_a;
            next_state <= s9;
        when s9 => 
            ack <= '1';
            next_state <= s10;
        when s10 => 
            next_state <= s11;
        when s11 => 
            ack <= '0';
            next_state <= s_init;
        when others =>
            next_state <= s_init;
            
    end case;
  end process cl;

  -- Registers

  seq : process (clk, reset)
--  seq : process (all)
  begin

    if rising_edge(clk) then
       
        if reset = '1' then
            state <= s_init;
            reg_a <= (others => '0');
            reg_b <= (others => '0');
        else
            if state = s_found then
                C <= reg_a;
            elsif state = s11 then
                C <= (others => 'U');
--                C <= (others => '0');
--            elsif state = s_input_A_read then
            else
                reg_a <= next_reg_a;
                reg_b <= next_reg_b; 
            end if;
            state <= next_state;
        end if;        
    
    end if;        

  end process seq;


end fsmd;
