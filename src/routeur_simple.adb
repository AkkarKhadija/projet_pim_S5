with Ada.Strings;               use Ada.Strings;	-- pour Both utilisé par Trim
with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Integer_Text_IO;       use Ada.Integer_Text_IO;
with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Text_IO.Unbounded_IO;  use Ada.Text_IO.Unbounded_IO;
with Ada.Command_Line;          use Ada.Command_Line;
with Ada.Exceptions;            use Ada.Exceptions;	-- pour Exception_Message

package body Routeur_Simple is

   procedure Analyser_L_Commande (T_Fichier : out Unbounded_String; P_Fichier : out Unbounded_String; R_Fichier : out Unbounded_String) is
      k : Integer;        -- variable compteur;
   begin
      k := 1;
      T_Fichier := To_Unbounded_String("table.txt");
      P_Fichier := To_Unbounded_String ("paquets.txt");
      R_Fichier := To_Unbounded_String  ("resultats.txt");
      while k <= Argument_Count loop
         if Argument(k) = "t" then
            T_Fichier := To_Unbounded_String (Argument(k+1));
            k := k + 2;
         elsif Argument(k) = "p" then
            P_Fichier := To_Unbounded_String (Argument(k+1));
            k := k + 2;
         elsif Argument(k) = "r" then
            R_Fichier := To_Unbounded_String (Argument(k+1));
            k := k + 2;
         else
            null;
         end if;
      end loop;
   end Analyser_L_Commande;

   procedure Enregistrer_Table(Table : in out T_Table; D : in T_Adresse_IP; M : in T_Adresse_IP; I : in Unbounded_String) is
   begin
      if Table = null then
         Table := new T_Route_Table;
         Table.all.Destination := D;
         Table.all.Masque := M;
         Table.all.Interface_T := I;
         Table.all.Suivante := null;
      else
         Enregistrer_Table (Table.all.Suivante, D, M, I);
      end if;
   end Enregistrer_Table;

   procedure Get_IP (Fichier : in File_Type; IP : out T_Adresse_IP) is
      UN_OCTET: constant T_Adresse_IP := 2 ** 8;
      Valeur : Integer;
      txt : Character;
      IP1 : T_Adresse_IP;
   begin
      IP := 1;
      for i in 0..3 loop
         Get (Fichier, Valeur);
         IP1 := T_Adresse_IP(Valeur);
         IP := IP * UN_OCTET + IP1;
         Get (Fichier, txt);
      end loop;
   end Get_IP;

   procedure Commande_Paquets(Paquets_txt : in File_Type; Stop : out Boolean; i : in out Integer; Table : in out T_Table; IP : out T_Adresse_IP) is
      Valeur : Integer;
      val : Unbounded_String;
   begin
      Get (Paquets_txt, Valeur);
      if To_Unbounded_String (Valeur) = "" then
         val :=  Get_Line(Paquets_txt);
         if val = "table" then
            Put ("table (ligne "); Put (i); Put (")");
            New_Line;
            Afficher_T(Table);
            Get_IP(Paquets_txt, IP);
            i := i + 2;
         elsif val = "fin" then
            Put ("fin (ligne "); Put (i); Put (")");
            stop := True;
         else
            i := i + 1;
         end if;
      else
         Get_IP(Paquets_txt, IP);
         i := i + 1;
      end if;
   exception
         when others => null;
   end Commande_Paquets;

   procedure Remplire_Table(Fichier : in File_Type; Table : in out T_Table) is
      UN_OCTET: constant T_Adresse_IP := 2 ** 8;
      IP : T_Adresse_IP;
      M : T_Adresse_IP;
      I : Unbounded_String;
   begin
      loop
         Get_IP(Fichier, IP);
         Get_IP(Fichier, M);
         I := Get_Line(Fichier);
         Enregistrer_Table(Table, IP, M, I);
      exit when End_Of_File(Fichier);
      end loop;

   end Remplire_Table;

   procedure Afficher_T (Table :in out T_Table) is
      UN_OCTET: constant T_Adresse_IP := 2 ** 8;
   begin
      while Table /= null loop
         Put (Natural ((Table.all.Destination / UN_OCTET ** 3) mod UN_OCTET), 1); Put (".");
         Put (Natural ((Table.all.Destination / UN_OCTET ** 2) mod UN_OCTET), 1); Put (".");
         Put (Natural ((Table.all.Destination / UN_OCTET ** 1) mod UN_OCTET), 1); Put (".");
         Put (Natural  (Table.all.Destination mod UN_OCTET), 1);
         Put (" " );
         Put (Natural ((Table.all.Masque / UN_OCTET ** 3) mod UN_OCTET), 1); Put (".");
         Put (Natural ((Table.all.Masque / UN_OCTET ** 2) mod UN_OCTET), 1); Put (".");
         Put (Natural ((Table.all.Masque / UN_OCTET ** 1) mod UN_OCTET), 1); Put (".");
         Put (Natural  (Table.all.Masque mod UN_OCTET), 1);
         Put (" " & Table.all.Interface_T);
         New_Line;
         Table := Table.all.Suivante;
      end loop;
   end Afficher_T;

   procedure Donner_Resultats(Table : in out T_Table) is
      UN_OCTET     : constant T_Adresse_IP := 2 ** 8;
      paquets_txt  :  File_Type;
      Resultats_txt: File_Type;
      IP           : T_Adresse_IP;
      Table0      : T_Table;
      T_Fichier : Unbounded_String;
      P_Fichier : Unbounded_String;
      R_Fichier : Unbounded_String;
      i : Integer;
      Stop : Boolean;
   begin
      Analyser_L_Commande (T_Fichier, P_Fichier, R_Fichier);
      Create(Resultats_txt, Out_File, To_String(R_Fichier));
      Open(paquets_txt, In_File, To_String(P_Fichier));
      begin
            i := 1;
            Stop := False;
         loop

            Commande_Paquets (paquets_txt, Stop, i, Table, IP);
            Table0 := Table;
            loop
               if (IP = Table0.all.Destination) and (Table0.all.Masque /= 0) then
                  Put (Resultats_txt, Natural ((Table0.all.Destination / UN_OCTET ** 3) mod UN_OCTET), 1); Put (Resultats_txt,".");
                  Put (Resultats_txt, Natural ((Table0.all.Destination / UN_OCTET ** 2) mod UN_OCTET), 1); Put (Resultats_txt,".");
                  Put (Resultats_txt, Natural ((Table0.all.Destination / UN_OCTET ** 1) mod UN_OCTET), 1); Put (Resultats_txt,".");
                  Put (Resultats_txt, Natural  (Table0.all.Destination mod UN_OCTET), 1);
                  Put (Resultats_txt, " " & Table0.all.Interface_T);
                  New_Line(Resultats_txt);
                  Table0 := Table0.all.Suivante;
               else
                  Table0 := Table0.all.Suivante;
               end if;
               exit when Table0.all.Suivante = null;
            end loop;
         exit when End_Of_File(paquets_txt) or stop;
         end loop;
      exception
         when End_Error =>
            Put ("Blancs en surplus à la fin du fichier.");
            null;
      end;
      Close (paquets_txt);
      Close (Resultats_txt);
   exception
      when E : others =>
         Put_Line (Exception_Message (E));
   end Donner_Resultats;

   procedure Pour_Chaque (Table : in T_Table) is
	begin
      if Table /= null then
         Traiter (Table.all.Destination, Table.all.Masque, Table.all.Interface_T);
         Pour_Chaque (Table.all.Suivante);
      else
         null;
      end if;
   exception
         when others => null;
   end Pour_Chaque;

end Routeur_Simple;