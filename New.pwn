#include <a_samp>
#include <Pawn.CMD>
#include <sscanf2>
#include <foreach>
#include <a_mysql>

//�������
#define MYSQL_HOST			"127.0.0.1"
#define MYSQL_USER			"root"
#define MYSQL_DATABASE		"vmafftesting"
#define MYSQL_PASSWORD		""
#define MAX_PASSWORD        31
#define MODE_VERSION		"Vmaff's v0.005"

//������
#define INFINITY            Float:0x7F800000
#define COMMANDS_QTY		14
#define MAX_INV_SLOTS		10

//������
#define LS_SPAWN			(2, 1277.4312, -1539.7104, 13.5589, 272.0752 , 0, 0, 0, 0, 0, 0)

//�����
#define RP_COLOR			0xC2A2DA00
#define COLOR_GREY			0xC0C0C0FF
#define COLOR_GREEN			0x9EC73DAA
#define COLOR_RED			0xFF6347AA
#define COLOR_YELLOW		0xFFFF00AA

//���������� � �������
new MySQL:dbHandle;

//������������ �������, ������ ������--�������--��������
enum e_cmds {
	cmd_access[4],
	cmd_text[24],
	cmd_desc[128]
};

//����� ������ - 14, �������� �������� � ������� 17, ��������������!
new cmds[][e_cmds] = {
	{"adm", "/makeadm", "������ ������ ������� ������� ������."},
	{"adm", "/admlvl", "�������� ������� ������� ������."},
	{"adm", "/deladm", "����� ������ � �������."},
	{"adm", "/weap", "������ ���� ������ � �������."},
	{"adm", "/heal", "�������� ������ �� 100��."},
	{"adm", "/agm", "��������� ��. ����������."},
	{"com", "/veh", "�������� ����������."},
	{"com", "/delveh", "�������� ����������."},
	{"com", "/setskin", "����� ����� ���������."},
	{"com", "/pm", "������ ��������� ������."},
	{"com", "/me", "��������� �������� �� �������� ����."},
	{"com", "/do", "��������� �������� �� �������."},
	{"com", "/help", "������ �� ��������"},
	{"com", "/inv", "�������� ��������� ���������."}
};

new allitems[][32] = {
	"�������",
	"�������"
};

//���������� �� ������
enum e_pInfo {
	pID,
	pName [MAX_PLAYER_NAME],
	pPassword [MAX_PASSWORD],
	pMoney,
	Float:pX,
	Float:pY,
	Float:pZ,
	pAdmin,
	bool:pInGame
};

enum e_pInventory {
	itemID,
	ownerID,
	itemType,
	itemValue[8]
};

new pInfo[MAX_PLAYERS][e_pInfo];
new pInv[MAX_INV_SLOTS][e_pInventory];

public OnGameModeInit()
{	
	SetGameModeText(MODE_VERSION);	
	ConnectMySql();
	return 1;
}

//������� � �����
stock ClearPInfo (playerid) {
	pInfo[playerid][pID] = 0;
	pInfo[playerid][pName][0] = EOS;
	pInfo[playerid][pPassword][0] = EOS;
	pInfo[playerid][pMoney] = 0;
	pInfo[playerid][pX] = 0.0;
	pInfo[playerid][pY] = 0.0;
	pInfo[playerid][pZ] = 0.0;
	pInfo[playerid][pAdmin] = 0;	
	pInfo[playerid][pInGame] = false;
	return 1;
}

//��� ������ �� ����
stock PlayerName(playerid) {
	new targetname[MAX_PLAYER_NAME];
	GetPlayerName(playerid, targetname, sizeof(targetname));
	return targetname;
}

//������� � ����
stock ConnectMySql() {
    dbHandle = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	switch(mysql_errno()) {
		case 0: printf("Database has connected successfully!");
		case 1044: printf("Database connection error.");
		case 1045: printf("Database connection error.");
		case 1049: printf("Database connection error.");
		case 2003: printf("Database connection error.");
		case 2005: printf("Database connection error.");
		default: printf("Database connection error: undefined error!");
	}
	return 1;
}

public OnGameModeExit()
{
	mysql_close(dbHandle);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	if (!pInfo[playerid][pInGame]) {
		return 0;
	}
	return 1;
}

public OnPlayerConnect(playerid)
{
	//�������� ����������� ��� ����������� � ��� ������
	ClearPInfo(playerid);

	//�������� ������� �������� � ����
	if (!pInfo[playerid][pInGame]) {
		GetPlayerName(playerid, pInfo[playerid][pName], MAX_PLAYER_NAME);
		new query[48 + MAX_PLAYER_NAME];
		format(query, sizeof(query), "SELECT * FROM `accounts` WHERE `name` = '%s'", pInfo[playerid][pName]);
		mysql_query(dbHandle, query, true);

		CheckAcc(playerid);		
	}
	
	SpawnPlayer(playerid);

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	SaveAcc(playerid); // ��������� ������ �� ��������
	ClearPInfo(playerid); // �� ������ ������ ��� �������� ����������
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

//�������� �� ������� ��������
stock CheckAcc(playerid) {
	new rows;
	cache_get_row_count(rows);
	
	//���� ������� ��� - ���� ���
	if (!rows) {
		ShowPlayerDialog(playerid, 8008, DIALOG_STYLE_INPUT, "�����������", "������� ���� ���� ������ ��� �����������.", "OK", "");
	//���� ���� - �����������
	} else {
		ShowPlayerDialog(playerid, 8009, DIALOG_STYLE_INPUT, "�����������", "������� ������ �� ��������.", "OK", "");
		cache_get_value_name(0, "password", pInfo[playerid][pPassword], MAX_PASSWORD);
	}
	
	return 1;
}

//���������� ������ �� ��������
stock SaveAcc(playerid) {
	new query[132 + MAX_PLAYER_NAME + MAX_PASSWORD + 11 + 1 + 33 + 3];
	GetPlayerPos(playerid, pInfo[playerid][pX], pInfo[playerid][pY], pInfo[playerid][pZ]);

	format(query, sizeof(query), "UPDATE `accounts` SET `name` = '%s', `password` = '%s', `money` = %d, `admin` = %d, `posX` = %f, `posY` = %f, `posZ` = %f WHERE `id` = %d", pInfo[playerid][pName], pInfo[playerid][pPassword], pInfo[playerid][pMoney], pInfo[playerid][pAdmin], pInfo[playerid][pX], pInfo[playerid][pY], pInfo[playerid][pZ], pInfo[playerid][pID]);
	mysql_query(dbHandle, query, false);
	return 1;
}

//�������� �� ������� � ������� � ����� ������� string[]
stock ProxDetector(playerid, Float:radi, string[], col1,col2,col3,col4,col5)
{
    new Float: Pos[3], Float: Radius;
    GetPlayerPos(playerid, Pos[0], Pos[1], Pos[2]);
    foreach(new i : Player)
    {
        Radius = GetPlayerDistanceFromPoint(i, Pos[0], Pos[1], Pos[2]);
        if (Radius < radi / 16) SendClientMessage(i, col1, string);
        else if(Radius < radi / 8) SendClientMessage(i, col2, string);
        else if(Radius < radi / 4) SendClientMessage(i, col3, string);
        else if(Radius < radi / 2) SendClientMessage(i, col4, string);
        else if(Radius < radi) SendClientMessage(i, col5, string);
    }
    return true;
}

//����������� � �������� ��������
stock CreateAcc(playerid, password[]) {
	new query[120 + MAX_PLAYER_NAME + MAX_PASSWORD + 11 + 1 + 33];
	
	format(query, sizeof(query), "INSERT INTO `accounts` (`name`, `password`, `money`, `admin`, `posx`, `posy`, `posz`) VALUES ('%s', '%s', %d, %d, %f, %f, %f)", pInfo[playerid][pName], password, pInfo[playerid][pMoney], pInfo[playerid][pAdmin], pInfo[playerid][pX], pInfo[playerid][pY], pInfo[playerid][pZ]);
	mysql_query(dbHandle, query, true);
	LoadAccID(playerid);
	
	SendClientMessage(playerid, COLOR_GREEN, "�� ������� ������������������!");
	pInfo[playerid][pInGame] = true;
	
	SpawnPlayer(playerid);
	
	return 1;
}

//�������� ��������� ������ ��� ���������� �������� � ����������
stock LoadAccID(playerid) {
	return pInfo[playerid][pID] = cache_insert_id();
}

//�������� ������ �� �������� � ����������
stock LoadAcc(playerid) {
	cache_get_value_name_int(0, "id", pInfo[playerid][pID]);
 	cache_get_value_name_int(0, "money", pInfo[playerid][pMoney]);
 	cache_get_value_name_int(0, "admin", pInfo[playerid][pAdmin]);	
	cache_get_value_name_float(0, "posx", pInfo[playerid][pX]);
	cache_get_value_name_float(0, "posy", pInfo[playerid][pY]);
	cache_get_value_name_float(0, "posz", pInfo[playerid][pZ]);
	SendClientMessage(playerid, COLOR_GREEN, "�� ������� ��������������!");
	pInfo[playerid][pInGame] = true;
	
	ShowPlayerDialog(playerid, 8013, DIALOG_STYLE_LIST, "����� ����� ������", "����������� �����\n���, ��� �����", "OK", "�����");

	return 1;
}

stock LoadInv(playerid) {
	new rows;
	new string[128];
	cache_get_row_count(rows);

	if (rows <= 0) {
		string = "��� ��������� ����!";
		return SendClientMessage(playerid, -1, string);
	}		

	for (new i; i < rows; i++) {
		cache_get_value_name_int(i, "id", pInv[i][itemID]);
		cache_get_value_name_int(i, "ownerid", pInv[i][ownerID]);
		cache_get_value_name_int(i, "type", pInv[i][itemType]);
		cache_get_value_name(i, "value", pInv[i][itemValue], 8);		
	}		

	return 1;	
}

public OnPlayerDeath(playerid, killerid, reason)
{
	//��������� ������������ �C ������ ��� ������
	SetSpawnInfo(playerid, 0, 2, 1277.4312, -1539.7104, 13.5589, 272.0752 , 0, 0, 0, 0, 0, 0);
	return 1;
}

public OnVehicleSpawn(vehicleid)
{
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	return 1;
}

public OnPlayerText(playerid, text[])
{
	//�������� � �������� ���������
	new string[256], playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername, sizeof(playername));

	format(string, sizeof(string), "%s �������: %s", playername, text);
	ProxDetector(playerid, 10.0, string, -1, -1, -1, -1, -1);
	SetPlayerChatBubble(playerid, text, -1, 10.0, 10000);
	ApplyAnimation(playerid, "PED", "IDLE_CHAT", 4.0, 0, 1, 1, 1, 1);
    SetTimerEx("ClearAnimText", 1500, false, "d", playerid);

	return 0;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveCheckpoint(playerid)
{
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	return 1;
}

public OnPlayerLeaveRaceCheckpoint(playerid)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnObjectMoved(objectid)
{
	return 1;
}

public OnPlayerObjectMoved(playerid, objectid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnVehicleMod(playerid, vehicleid, componentid)
{
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
	return 1;
}

public OnPlayerSelectedMenuRow(playerid, row)
{
	return 1;
}

public OnPlayerExitedMenu(playerid)
{
	return 1;
}

public OnPlayerInteriorChange(playerid, newinteriorid, oldinteriorid)
{
	return 1;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid)
{
	return 1;
}

public OnPlayerStreamOut(playerid, forplayerid)
{
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid) {
		//������ �����������
		case 8008: {
			if (!response) return ShowPlayerDialog(playerid, 8008, DIALOG_STYLE_INPUT, "�����������", "������� ���� ���� ������ ��� �����������.", "OK", "");
			
			//�������� �� ���������� �������� � ������
			if(strlen(inputtext) < 3 || strlen(inputtext) > 30) return ShowPlayerDialog(playerid, 8008, DIALOG_STYLE_INPUT, "�����������", "��� ������ ������ ��������� �� ������ 3 � �� ����� 30 ��������.", "OK", "");		
			
			format(pInfo[playerid][pPassword], MAX_PASSWORD, "%s", inputtext);
			CreateAcc(playerid, pInfo[playerid][pPassword]);
		}
		//������ �����������
		case 8009: {
			if (!response) return ShowPlayerDialog(playerid, 8009, DIALOG_STYLE_INPUT, "�����������", "������� ������ �� ��������.", "OK", "");
			
			//�������� �� ���������� �������� � ������
			if(strlen(inputtext) < 3 || strlen(inputtext) > 30) return ShowPlayerDialog(playerid, 8009, DIALOG_STYLE_INPUT, "�����������", "��� ������ ������ ��������� �� ������ 3 � �� ����� 30 ��������.", "OK", "");				
			
			//�������� �� ���������� �������
			if(!strcmp(pInfo[playerid][pPassword], inputtext)) {
				new query[48 + MAX_PLAYER_NAME];
				
				format(query, sizeof(query), "SELECT * FROM `accounts` WHERE `name` = '%s'", pInfo[playerid][pName]);
				mysql_query(dbHandle, query, true);
				LoadAcc(playerid);
			} else {
				if (GetPVarInt(playerid, "BadAttempt") >= 3) return Kick(playerid);
				new string[90];
				format(string, sizeof(string), "��������� ������ �������! ���������� ���������� �������: %d.\n������� ������.", 3 - GetPVarInt(playerid, "BadAttempt"));
				ShowPlayerDialog(playerid, 8009, DIALOG_STYLE_INPUT, "�����������", string, "OK", "");
				SetPVarInt(playerid, "BadAttempt", GetPVarInt(playerid, "BadAttempt") + 1);
			}
		}
		//������ ������ �� ��������
		case 8010: {
			if (!response) return 1;

			if (response) {
				switch (listitem) {
					case 0: {
						new string[256];
						new line[512];

						line = "�������\t��������";

						for (new i; i < COMMANDS_QTY; i++) {
							if (!strcmp(cmds[i][cmd_access], "adm", false))
								continue;

							format(string, sizeof(string), "\n%s\t%s", cmds[i][cmd_text], cmds[i][cmd_desc]);
							strcat(line, string);
						}
						ShowPlayerDialog(playerid, 8011, DIALOG_STYLE_TABLIST_HEADERS, "����� �������", line, "OK", "�����");
					}					
					case 1: {
						new string[256];
						new line[512];

						line = "�������\t��������";

						for (new i; i < COMMANDS_QTY; i++) {
							if (!strcmp(cmds[i][cmd_access], "com", false))
								continue;

							format(string, sizeof(string), "\n%s\t%s", cmds[i][cmd_text], cmds[i][cmd_desc]);
							strcat(line, string);
						}
						ShowPlayerDialog(playerid, 8011, DIALOG_STYLE_TABLIST_HEADERS, "��������� �������", line, "OK", "�����");
					}
				}
			}
		}
		//���������� ������ �� ��������
		case 8011: if (!response) return ShowPlayerDialog(playerid, 8010, DIALOG_STYLE_LIST, "������ �� ��������", "�����\n���������", "OK", "�����");
		case 8012: if (!response) return ShowPlayerDialog(playerid, 8010, DIALOG_STYLE_LIST, "������ �� ��������", "�����\n���������", "OK", "�����");
		//������ ������ ����� ������
		case 8013: {
			if (!response) 
				return ShowPlayerDialog(playerid, 8013, DIALOG_STYLE_LIST, "����� ����� ������", "����������� �����\n���, ��� �����", "OK", "�����");

			if (response) {
				switch (listitem) {
					case 0: SetSpawnInfo(playerid, 0, 2, 1277.4312, -1539.7104, 13.5589, 272.0752 , 0, 0, 0, 0, 0, 0); //����������� �����
					case 1: SetSpawnInfo(playerid, 0, 2, pInfo[playerid][pX], pInfo[playerid][pY], pInfo[playerid][pZ] + 0.5, 0, 0, 0, 0, 0, 0, 0); //����� �� ����� ������
				}
			}
			SpawnPlayer(playerid);
		}
		//������ ���������
		case 8014: {
			if (!response)
				return 1;
			if (response)
				return 1;
		}
	}
	return 1;
}

public OnPlayerClickPlayer(playerid, clickedplayerid, source)
{
	return 1;
}

//================= ������� CMD ==================//

//������ ������� ������
cmd:makeadm(playerid, params[]) {
	new admname[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME], string[128];

	if (pInfo[playerid][pAdmin] <= 4) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");
	
	if (sscanf(params, "d", params[0])) 
		return SendClientMessage(playerid, COLOR_GREY, "/makeadm [ID]");

	if (pInfo[params[0]][pAdmin] > 0)
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� ��� ����� �������!");
		
	if (IsPlayerConnected(params[0]) == 0) 
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� �� �� �������!");

	if (params[0] == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "������ ������ ������� ������ ����!");
		
	GetPlayerName(playerid, admname, sizeof(admname));
	GetPlayerName(params[0], targetname, sizeof(targetname));
		
	pInfo[params[0]][pAdmin] = 1;	
	format(string, sizeof(string), "%s[%d] ����� ������ %s[%d] ������� 1-�� ������.", admname, playerid, targetname, params[0]);
	SendClientMessageToAll(COLOR_RED, string); //�������, ������� �� ������ ��������� ������ �������

	return 1;
}

//������ ������� � ������
cmd:deladm(playerid, params[]) {
	new admname[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME], string[128];
	if (pInfo[playerid][pAdmin] <= 4) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");

	if (sscanf(params, "d", params[0]))
		return SendClientMessage(playerid, COLOR_GREY, "/deladm [ID]");			

	if (IsPlayerConnected(params[0]) == 0) 
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� �� �� �������!");

	if (pInfo[params[0]][pAdmin] <= 0)
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� �� ����� �������!");
	
	if (params[0] == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "������ ����� � ������� ����!");
	
	GetPlayerName(playerid, admname, sizeof(admname));
	GetPlayerName(params[0], targetname, sizeof(targetname));
	
	pInfo[params[0]][pAdmin] = 0;
	format(string, sizeof(string), "%s[%d] ���� � ������� ������ %s[%d].", admname, playerid, targetname, params[0]); 
	SendClientMessageToAll(COLOR_RED, string); //�� �����, ������� �� ������ ��������� ������ �������

	return 1;
}

//����� ������ ������� � ������
cmd:admlvl(playerid, params[]) {
	new admname[MAX_PLAYER_NAME], targetname[MAX_PLAYER_NAME], string[128];
	if (pInfo[playerid][pAdmin] <= 4) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");
	
	if (sscanf(params, "dd", params[0], params[1]))
		return SendClientMessage(playerid, COLOR_GREY, "/admlvl [ID] [�������]");			

	if (pInfo[params[0]][pAdmin] <= 0)
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� �� ����� ����� ����!");
	
	if (params[1] == 0)
		return SendClientMessage(playerid, COLOR_RED, "��� ������ ������ � ������� ����������� /deladm [ID].");

	if (params[0] == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "������ �������� ���� ������� ����� ����!");
	
	GetPlayerName(playerid, admname, sizeof(admname));
	GetPlayerName(params[0], targetname, sizeof(targetname));

	format(string, sizeof(string), "%s[%d] ������� ������� ������� ������ %s[%d] � %d �� %d.", admname, playerid, targetname, params[0], pInfo[params[0]][pAdmin], params[1]);
	pInfo[params[0]][pAdmin] = params[1];
	SendClientMessageToAll(COLOR_RED, string);//�� �����, ������� �� ������ ��������� ������ �������

	return 1;
}

//��������� ��
cmd:agm(playerid, params[]) {
	if (pInfo[playerid][pAdmin] <= 0) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");
	
	if (GetPVarInt(playerid, "agm") == 0) {
		SetPVarInt(playerid, "agm", 1);
		SetPlayerHealth(playerid, INFINITY); 
        SendClientMessage(playerid, COLOR_GREEN, "AGM ON"); 
	} else {
		SetPVarInt(playerid, "agm", 0); 
        SetPlayerHealth(playerid, 100.0); 
        SendClientMessage(playerid, COLOR_RED, "AGM OFF");
	}
	return 1;
}

//��������� ���
alias:achat("a");
cmd:achat(playerid, params[]) {
	new playername[MAX_PLAYER_NAME];
	new string[128];
	GetPlayerName(playerid, playername, sizeof(playername));

	format(string, sizeof(string), "[A] %s: %s", playername, params[0]);

	if (pInfo[playerid][pAdmin] <= 0) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");
	
	if (sscanf(params, "s", params[0]))
		return SendClientMessage(playerid, COLOR_GREY, "/a(chat) [���������]");

	//�������� ������ �� ���� ������� � �������� �� �� ������� �������, ���� �� - ������ ���������, ���� ��� - ���
	for (new i; i < MAX_PLAYERS; i++) {
		if (pInfo[i][pAdmin] <= 0)
			continue;
		else
			SendClientMessage(i, 0x46BBAA00, string);
	}

	return 1;
}

//������ ������ ������
cmd:weap(playerid, params[]) {
	if (pInfo[playerid][pAdmin] <= 0) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");
	
	if (sscanf(params, "dd", params[0], params[1]))
		return SendClientMessage(playerid, COLOR_GREY, "/weap [ID ������] [�������]");
		
	GivePlayerWeapon(playerid, params[0], params[1]);

	return 1;
}

//��� ������
cmd:heal(playerid, params[]) {
	new string[64];	

	if (pInfo[playerid][pAdmin] <= 0) 
		return SendClientMessage(playerid, COLOR_RED, "������ � ������� ��������!");

	if (sscanf(params, "d", params[0]))
		return SendClientMessage(playerid, COLOR_GREY, "/heal [ID]");	

	format(string, sizeof(string), "�� �������� ������ %s.", PlayerName(params[0]));

	if (IsPlayerConnected(params[0]) == 0) 
		return SendClientMessage(playerid, COLOR_RED, "��������� ����� �� �� �������!");	

	if (params[0] == playerid)
		format(string, sizeof(string), "�� �������� ����.");

	SetPlayerHealth(params[0], 100);
	SendClientMessage(playerid, COLOR_GREEN, string);

	return 1;
}

//����� ������������ �����
cmd:setskin(playerid, params[]) {
	new skinid;
	skinid = strval(params[0]);
	
	if (sscanf(params, "d", params[0]))
		return SendClientMessage(playerid, COLOR_GREY, "/setskin [ID]");
	
	SetPlayerSkin(playerid, skinid);

	return 1;
}

//������ ���������
cmd:pm(playerid, params[]) {
	new string[256];
	new sendername[MAX_PLAYER_NAME];
	new targetname[MAX_PLAYER_NAME];
	new targetid;
	
	targetid = strval(params[0]);
	
	GetPlayerName(targetid, targetname, sizeof(targetname));
	GetPlayerName(playerid, sendername, sizeof(sendername));
	
	if (sscanf(params, "ds", params[0], params[1])) 
		return SendClientMessage(playerid, COLOR_GREY, "/pm [ID] [���������]");
	
	if (!IsPlayerConnected(params[0])) 
		return SendClientMessage(playerid, COLOR_RED, "����� � ����� ID �� �� �������!");		
	
	if (params[0] == playerid) 
		return SendClientMessage(playerid, COLOR_RED, "������ ��������� ��������� ������ ����.");
	
	format(string, sizeof(string), "(( PM � %s[%d]: %s ))", targetname, targetid, params[1]);
	SendClientMessage(playerid, COLOR_YELLOW, string);
	
	format(string, sizeof(string), "(( PM �� %s[%d]: %s ))", sendername, playerid, params[1]);
	SendClientMessage(params[0], COLOR_YELLOW, string);	
	
	return 1;
}

//�����������
cmd:me(playerid, params[]) {    
	new playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername, sizeof(playername));
	
	//�������� �� ���������� �������� ������� � ������� ����������
    if (sscanf(params, "s[128]", params[0])) 
		return SendClientMessage(playerid, COLOR_GREY, "/me [��������]");

    new string[128];
	format(string, sizeof(string), "* %s %s", playername, params[0]);
	ProxDetector(playerid, 15.0, string, RP_COLOR, RP_COLOR, RP_COLOR, RP_COLOR, RP_COLOR);
	return 1;
}

//�������� � �� �������
cmd:do(playerid, params[]) {
	new playername[MAX_PLAYER_NAME];
	GetPlayerName(playerid, playername, sizeof(playername));
	
	//�������� �� ���������� �������� ������� � ������� ����������
    if (sscanf(params, "s[128]", params[0])) 
		return SendClientMessage(playerid, COLOR_GREY, "/do [��������]");

    new string[128];
	format(string, sizeof(string), "* %s (( %s ))", params[0], playername);
	ProxDetector(playerid, 15.0, string, RP_COLOR, RP_COLOR, RP_COLOR, RP_COLOR, RP_COLOR);
	return 1;
}

//�������� ����������
cmd:veh(playerid, params[]) {
	new vehid, newvehid, color1, color2;
	new Float:x, Float:y, Float:z;

	GetPlayerPos(playerid, x, y, z);
	
	if (IsPlayerInAnyVehicle(playerid))
		return SendClientMessage(playerid, COLOR_RED, "�� ��� ���������� � ����������!");

	//�������� �� ���������� �������� ������� � ������� ����������
	if	(sscanf(params, "ddd", vehid, color1, color2)) 
		return SendClientMessage(playerid, COLOR_GREY, "/veh [ID ����������] [����1] [����2]");

	newvehid = CreateVehicle(vehid, x, y, z, 90, color1, color2, -1);
	PutPlayerInVehicle(playerid, newvehid, 0);
		
	SendClientMessage(playerid, COLOR_GREEN, "�� ������� ������� ���������!");

	return 1;
}

//�������� ����������
cmd:delveh(playerid, params[]) {
	new vehid;
	
	vehid = GetPlayerVehicleID(playerid);
	if (!vehid) 
		return SendClientMessage(playerid, COLOR_RED, "�� �� � ������!");

	DestroyVehicle(vehid);

	return 1;
}

//�����, ������ �� ��������
alias:help("commands");
cmd:help(playerid, params[]) {
	ShowPlayerDialog(playerid, 8010, DIALOG_STYLE_LIST, "������ �� ��������", "�����\n���������", "OK", "�����");

	return 1;
}

//���������
cmd:inv(playerid, params[]) {
	new query[128];
	new line[256], string[64];

	line = "#\t�������\t����������/��������";

	//�������� ������ � ���� �� ownerid
	format(query, sizeof(query), "SELECT * FROM `items` WHERE `ownerid` = %d", pInfo[playerid][pID]);
	mysql_query(dbHandle, query, true);
	LoadInv(playerid);

	//���������� �� ������ ���������� ������� � ���������
	for (new i; i < MAX_INV_SLOTS; i++) {
		if (pInv[i][itemID]) {						
			printf("%d - %s", pInv[i][itemType], allitems[pInv[i][itemType]]);
			format(string, sizeof(string), "\n%d\t%s\t%s", i+1, allitems[pInv[i][itemType]], pInv[i][itemValue]);		
		}
		else 
			format(string, sizeof(string), "\n%d\t�����\t0", i+1);
		strcat(line, string);
	}

	ShowPlayerDialog(playerid, 8014, DIALOG_STYLE_TABLIST_HEADERS, "��������� ���������", line, "OK", "�����");

	return 1;
}