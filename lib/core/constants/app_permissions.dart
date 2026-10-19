import '../models/user_model.dart';

class AppPermissions {
  // Navigation / Módulos principales
  static const String posAccess = 'pos:access';
  static const String membersAccess = 'members:access';
  static const String accessControlAccess = 'access:access';
  static const String cashAccess = 'cash:access';
  static const String inventoryAccess = 'inventory:access';
  static const String employeesAccess = 'employees:access';
  static const String campaignsAccess = 'campaigns:access';
  static const String reportsAccess = 'reports:access';
  static const String settingsAccess = 'settings:access';

  // Acciones en Punto de Venta
  static const String posSell = 'pos:sell';
  static const String posVoidSale = 'pos:void_sale';
  static const String posApplyDiscount = 'pos:apply_discount';

  // Acciones en Caja & Arqueo
  static const String cashOpen = 'cash:open';
  static const String cashClose = 'cash:close';
  static const String cashWithdraw = 'cash:withdraw';
  static const String cashViewHistory = 'cash:view_history';

  // Acciones en Socios & Membresías
  static const String membersCreate = 'members:create';
  static const String membersEdit = 'members:edit';
  static const String membersDelete = 'members:delete';
  static const String membersAssignMembership = 'members:assign_membership';
  static const String membersCancelMembership = 'members:cancel_membership';

  // Acciones en Inventario & Productos
  static const String inventoryCreate = 'inventory:create';
  static const String inventoryEdit = 'inventory:edit';
  static const String inventoryAdjustStock = 'inventory:adjust_stock';
  static const String inventoryDelete = 'inventory:delete';

  // Acciones en Nómina & Empleados
  static const String employeesManage = 'employees:manage';
  static const String employeesPayroll = 'employees:payroll';
  static const String employeesAssignRole = 'employees:assign_role';

  // Acciones en Control de Acceso
  static const String accessManualEntry = 'access:manual_entry';

  // Acciones en Envíos Masivos
  static const String campaignsSend = 'campaigns:send';

  // Acciones en Reportes & Métricas
  static const String reportsExport = 'reports:export';

  // Acciones en Configuración
  static const String settingsEditGym = 'settings:edit_gym';
  static const String settingsManageRoles = 'settings:manage_roles';

  /// Permisos por defecto de cada rol (alineados con el Backend gym-backend)
  static const Map<UserRole, List<String>> defaultRolePermissions = {
    UserRole.admin: [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw, cashViewHistory,
      membersAccess, membersCreate, membersEdit, membersDelete, membersAssignMembership, membersCancelMembership,
      inventoryAccess, inventoryCreate, inventoryEdit, inventoryAdjustStock, inventoryDelete,
      employeesAccess, employeesManage, employeesPayroll, employeesAssignRole,
      accessControlAccess, accessManualEntry,
      campaignsAccess, campaignsSend,
      reportsAccess, reportsExport,
      settingsAccess, settingsEditGym, settingsManageRoles,
    ],
    UserRole.encargado: [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw, cashViewHistory,
      membersAccess, membersCreate, membersEdit, membersAssignMembership, membersCancelMembership,
      inventoryAccess, inventoryCreate, inventoryEdit, inventoryAdjustStock,
      employeesAccess,
      accessControlAccess, accessManualEntry,
      campaignsAccess, campaignsSend,
      reportsAccess, reportsExport,
      settingsAccess, settingsEditGym,
    ],
    UserRole.empleadoCajero: [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw,
      membersAccess, membersCreate, membersEdit, membersAssignMembership,
      inventoryAccess,
      accessControlAccess, accessManualEntry,
    ],
    UserRole.empleadoEntrenador: [
      membersAccess,
      accessControlAccess,
    ],
    UserRole.cliente: [],
  };

  static const Map<String, List<String>> defaultRolePermissionsAsStrings = {
    'admin': [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw, cashViewHistory,
      membersAccess, membersCreate, membersEdit, membersDelete, membersAssignMembership, membersCancelMembership,
      inventoryAccess, inventoryCreate, inventoryEdit, inventoryAdjustStock, inventoryDelete,
      employeesAccess, employeesManage, employeesPayroll, employeesAssignRole,
      accessControlAccess, accessManualEntry,
      campaignsAccess, campaignsSend,
      reportsAccess, reportsExport,
      settingsAccess, settingsEditGym, settingsManageRoles,
    ],
    'encargado': [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw, cashViewHistory,
      membersAccess, membersCreate, membersEdit, membersAssignMembership, membersCancelMembership,
      inventoryAccess, inventoryCreate, inventoryEdit, inventoryAdjustStock,
      employeesAccess,
      accessControlAccess, accessManualEntry,
      campaignsAccess, campaignsSend,
      reportsAccess, reportsExport,
      settingsAccess, settingsEditGym,
    ],
    'empleado_cajero': [
      posAccess, posSell, posVoidSale, posApplyDiscount,
      cashAccess, cashOpen, cashClose, cashWithdraw,
      membersAccess, membersCreate, membersEdit, membersAssignMembership,
      inventoryAccess,
      accessControlAccess, accessManualEntry,
    ],
    'empleado_entrenador': [
      membersAccess,
      accessControlAccess,
    ],
    'cliente': [],
  };

  static const List<Map<String, String>> catalogDefinitions = [
    // Punto de Venta
    {
      'id': 'pos:access',
      'name': 'Acceso a Punto de Venta',
      'description': 'Permite abrir y ver la pantalla del Punto de Venta',
      'module': 'Punto de Venta',
    },
    {
      'id': 'pos:sell',
      'name': 'Cobrar y Realizar Ventas',
      'description': 'Permite agregar productos al carrito y procesar cobros',
      'module': 'Punto de Venta',
    },
    {
      'id': 'pos:void_sale',
      'name': 'Anular / Cancelar Ventas',
      'description': 'Permite anular ventas del turno activo y reponer stock',
      'module': 'Punto de Venta',
    },
    {
      'id': 'pos:apply_discount',
      'name': 'Aplicar Descuentos',
      'description': 'Permite aplicar descuentos manuales en mostrador',
      'module': 'Punto de Venta',
    },

    // Caja & Arqueo
    {
      'id': 'cash:access',
      'name': 'Acceso a Caja y Arqueo',
      'description': 'Permite ver el control de caja y ventas del turno',
      'module': 'Caja & Arqueo',
    },
    {
      'id': 'cash:open',
      'name': 'Abrir Caja / Turno',
      'description': 'Permite registrar el fondo inicial para abrir la caja',
      'module': 'Caja & Arqueo',
    },
    {
      'id': 'cash:close',
      'name': 'Cerrar Caja y Arqueo',
      'description': 'Permite realizar el arqueo, desglose de billetes y cierre',
      'module': 'Caja & Arqueo',
    },
    {
      'id': 'cash:withdraw',
      'name': 'Registrar Salidas de Efectivo',
      'description': 'Permite registrar gastos y retiros de efectivo de la gaveta',
      'module': 'Caja & Arqueo',
    },
    {
      'id': 'cash:view_history',
      'name': 'Ver Historial de Cierres',
      'description': 'Permite ver turnos anteriores y el detalle de ventas pasadas',
      'module': 'Caja & Arqueo',
    },

    // Socios & Membresías
    {
      'id': 'members:access',
      'name': 'Acceso a Socios y Membresías',
      'description': 'Permite consultar el listado y detalle de socios',
      'module': 'Socios & Membresías',
    },
    {
      'id': 'members:create',
      'name': 'Registrar Nuevos Socios',
      'description': 'Permite crear nuevos clientes y perfiles de socios',
      'module': 'Socios & Membresías',
    },
    {
      'id': 'members:edit',
      'name': 'Editar Datos de Socios',
      'description': 'Permite actualizar datos personales, teléfono y dirección',
      'module': 'Socios & Membresías',
    },
    {
      'id': 'members:delete',
      'name': 'Eliminar / Desactivar Socios',
      'description': 'Permite dar de baja o desactivar cuentas de socios',
      'module': 'Socios & Membresías',
    },
    {
      'id': 'members:assign_membership',
      'name': 'Asignar / Renovar Membresías',
      'description': 'Permite cobrar planes, planes grupales y suscripciones',
      'module': 'Socios & Membresías',
    },
    {
      'id': 'members:cancel_membership',
      'name': 'Cancelar Membresía',
      'description': 'Permite anular o cancelar planes de socios',
      'module': 'Socios & Membresías',
    },

    // Inventario & Productos
    {
      'id': 'inventory:access',
      'name': 'Acceso a Inventario',
      'description': 'Permite ver el catálogo de productos y existencias',
      'module': 'Inventario & Productos',
    },
    {
      'id': 'inventory:create',
      'name': 'Crear Nuevos Productos',
      'description': 'Permite dar de alta productos en el inventario',
      'module': 'Inventario & Productos',
    },
    {
      'id': 'inventory:edit',
      'name': 'Editar Productos y Precios',
      'description': 'Permite modificar nombres, costos, precios y alertas',
      'module': 'Inventario & Productos',
    },
    {
      'id': 'inventory:adjust_stock',
      'name': 'Ajustar Stock / Entradas',
      'description': 'Permite modificar unidades físicas y registrar compras',
      'module': 'Inventario & Productos',
    },
    {
      'id': 'inventory:delete',
      'name': 'Eliminar Productos',
      'description': 'Permite remover productos del inventario',
      'module': 'Inventario & Productos',
    },

    // Nómina & Empleados
    {
      'id': 'employees:access',
      'name': 'Acceso a Nómina y Empleados',
      'description': 'Permite consultar la plantilla de empleados',
      'module': 'Nómina & Empleados',
    },
    {
      'id': 'employees:manage',
      'name': 'Crear y Editar Empleados',
      'description': 'Permite registrar empleados y modificar sus datos laborales',
      'module': 'Nómina & Empleados',
    },
    {
      'id': 'employees:payroll',
      'name': 'Procesar Pagos de Nómina',
      'description': 'Permite liquidar y pagar salarios a empleados',
      'module': 'Nómina & Empleados',
    },
    {
      'id': 'employees:assign_role',
      'name': 'Asignar Roles a Usuarios',
      'description': 'Permite convertir usuarios o cambiar roles en el sistema',
      'module': 'Nómina & Empleados',
    },

    // Control de Acceso
    {
      'id': 'access:access',
      'name': 'Acceso a Control de Acceso',
      'description': 'Permite ver el registro de entradas y torniquete',
      'module': 'Control de Acceso',
    },
    {
      'id': 'access:manual_entry',
      'name': 'Marcar Entrada Manual',
      'description': 'Permite validar y dar paso manual a socios en torniquete',
      'module': 'Control de Acceso',
    },

    // Envíos Masivos
    {
      'id': 'campaigns:access',
      'name': 'Acceso a Envíos Masivos',
      'description': 'Permite ver campañas de WhatsApp y plantillas',
      'module': 'Envíos Masivos',
    },
    {
      'id': 'campaigns:send',
      'name': 'Enviar Campañas Masivas',
      'description': 'Permite lanzar mensajes masivos de WhatsApp a socios',
      'module': 'Envíos Masivos',
    },

    // Reportes & Métricas
    {
      'id': 'reports:access',
      'name': 'Acceso a Reportes y Métricas',
      'description': 'Permite ver ingresos, estadísticas y métricas del negocio',
      'module': 'Reportes & Métricas',
    },
    {
      'id': 'reports:export',
      'name': 'Exportar Reportes (Excel / PDF)',
      'description': 'Permite descargar información financiera o de auditoría',
      'module': 'Reportes & Métricas',
    },

    // Configuración
    {
      'id': 'settings:access',
      'name': 'Acceso a Configuración',
      'description': 'Permite ingresar a la pantalla de configuración',
      'module': 'Configuración',
    },
    {
      'id': 'settings:edit_gym',
      'name': 'Editar Datos de Empresa y Gimnasio',
      'description': 'Permite modificar RNC, nombre, teléfonos y formato de ticket',
      'module': 'Configuración',
    },
    {
      'id': 'settings:manage_roles',
      'name': 'Gestionar Roles y Permisos',
      'description': 'Permite modificar las acciones habilitadas para cada rol',
      'module': 'Configuración',
    },
  ];
}
