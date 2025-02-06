'use strict'

const St = imports.gi.St;
const Main = imports.ui.main;
const Shell = imports.gi.Shell;
const Meta = imports.gi.Meta;
const GLib = imports.gi.GLib;

let windowCreatedSignal, windowClosedSignal, workspaceSwitchedSignal;

function enable() {
    log("[AutoTile] Ativando extensão...");

    // Detecta quando uma nova janela é criada e chama AutoTileMain
    windowCreatedSignal = global.display.connect('window-created', () => {
        log("[AutoTile] Janela criada, chamando AutoTileMain...");
        GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
            AutoTileMain();
            return GLib.SOURCE_REMOVE;
        });
    });

    // Detecta quando uma janela é fechada e chama AutoTileMain
    windowClosedSignal = global.display.connect('window-destroy', () => {
        log("[AutoTile] Janela fechada, chamando AutoTileMain...");
        GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
            AutoTileMain();
            return GLib.SOURCE_REMOVE;
        });
    });

    // Detecta quando o workspace é alterado e chama AutoTileMain
    workspaceSwitchedSignal = global.workspace_manager.connect('workspace-switched', () => {
        log("[AutoTile] Área de trabalho alterada, chamando AutoTileMain...");
        GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
            AutoTileMain();
            return GLib.SOURCE_REMOVE;
        });
    });

    log("[AutoTile] Extensão ativada!");
}

function disable() {
    log("[AutoTile] Desativando extensão...");

    if (windowCreatedSignal) {
        global.display.disconnect(windowCreatedSignal);
        windowCreatedSignal = null;
    }
    if (windowClosedSignal) {
        global.display.disconnect(windowClosedSignal);
        windowClosedSignal = null;
    }
    if (workspaceSwitchedSignal) {
        global.workspace_manager.disconnect(workspaceSwitchedSignal);
        workspaceSwitchedSignal = null;
    }

    log("[AutoTile] Extensão desativada!");
}

// Função AutoTileMain simulada para evitar erro caso não esteja definida
function AutoTileMain() {
    log("[AutoTile] AutoTileMain chamado!");
}
