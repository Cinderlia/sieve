#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "php.h"
#include "php_ini.h"
#include "ext/standard/info.h"
#include "php_opcode_tracer.h"
#include "zend_execute.h"
#include "zend_vm.h"
#include "zend_vm_opcodes.h"
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef ZEND_VM_LAST_OPCODE
#define ZEND_VM_LAST_OPCODE 255
#endif

static FILE *trace_fp = NULL;
static char only_prefix[PATH_MAX] = {0};

static zend_always_inline bool opcode_tracer_is_jump_opcode(zend_uchar opcode)
{
    return opcode == ZEND_JMP || opcode == ZEND_JMPZ || opcode == ZEND_JMPNZ;
}

static zend_always_inline long opcode_tracer_get_jump_target(
    const zend_op *base_opcodes,
    const zend_op *opline,
    long opidx
)
{
#if ZEND_USE_ABS_JMP_ADDR
    if (base_opcodes && opline->op2.jmp_addr) {
        return (long)(opline->op2.jmp_addr - base_opcodes);
    }
    return -1;
#else
    (void) base_opcodes;
    return opidx + (long) opline->op2.jmp_offset + 1;
#endif
}

static int opcode_tracer_handler(zend_execute_data *execute_data)
{
    if (trace_fp && execute_data && execute_data->opline) {
        const zend_op *opline = execute_data->opline;
        const char *filename = NULL;
        const zend_op_array *op_array = NULL;
        
        if (execute_data && execute_data->func && ZEND_USER_CODE(execute_data->func->type)) {
            op_array = &execute_data->func->op_array;
            filename = ZSTR_VAL(op_array->filename);
        }
        
        if (filename) {
            char resolved_path[PATH_MAX];
            const char *path_out = filename;
            if (realpath(filename, resolved_path)) {
                path_out = resolved_path;
            }
            if (only_prefix[0]) {
                size_t L = strlen(only_prefix);
                if (strncmp(path_out, only_prefix, L) != 0) {
                    return ZEND_USER_OPCODE_DISPATCH;
                }
            }
            if (strstr(path_out, "php_ast_extractor.php") != NULL) {
                return ZEND_USER_OPCODE_DISPATCH;
            }
            const char *opname = zend_get_opcode_name(opline->opcode);
            long opidx = -1;
            long target_idx = -1;
            if (op_array && op_array->opcodes) {
                opidx = (long)(opline - op_array->opcodes);
            }
            char o1[128] = {0}, o2[128] = {0}, res[64] = {0};
            if (opline->op1_type == IS_CV) {
                int cv = opline->op1.var;
                if (op_array && op_array->vars && cv >= 0 && cv < (int) op_array->last_var) {
                    const char *vname = ZSTR_VAL(op_array->vars[cv]);
                    snprintf(o1, sizeof(o1), "CV:%s", vname ? vname : "");
                } else {
                    snprintf(o1, sizeof(o1), "CV:%d", cv);
                }
            } else if (opline->op1_type == IS_CONST) {
                snprintf(o1, sizeof(o1), "CONST:%u", (unsigned)opline->op1.constant);
            } else if (opline->op1_type == IS_TMP_VAR) {
                snprintf(o1, sizeof(o1), "TMP");
            } else if (opline->op1_type == IS_VAR) {
                snprintf(o1, sizeof(o1), "VAR");
            }
            if (opline->op2_type == IS_CV) {
                int cv = opline->op2.var;
                if (op_array && op_array->vars && cv >= 0 && cv < (int) op_array->last_var) {
                    const char *vname = ZSTR_VAL(op_array->vars[cv]);
                    snprintf(o2, sizeof(o2), "CV:%s", vname ? vname : "");
                } else {
                    snprintf(o2, sizeof(o2), "CV:%d", cv);
                }
            } else if (opline->op2_type == IS_CONST) {
                snprintf(o2, sizeof(o2), "CONST:%u", (unsigned)opline->op2.constant);
            } else if (opline->op2_type == IS_TMP_VAR) {
                snprintf(o2, sizeof(o2), "TMP");
            } else if (opline->op2_type == IS_VAR) {
                snprintf(o2, sizeof(o2), "VAR");
            }
            if (opline->result_type == IS_TMP_VAR) {
                snprintf(res, sizeof(res), "TMP");
            } else if (opline->result_type == IS_VAR) {
                snprintf(res, sizeof(res), "VAR");
            } else if (opline->result_type == IS_CV) {
                snprintf(res, sizeof(res), "CV");
            }
            const char *funcname = NULL;
            if (execute_data->func && execute_data->func->common.function_name) {
                funcname = ZSTR_VAL(execute_data->func->common.function_name);
            }
            int is_entry = (op_array && opline->lineno == (uint32_t) op_array->line_start);
            char cvmap_buf[1024]; cvmap_buf[0] = '\0';
            if (is_entry && op_array && op_array->vars && op_array->last_var > 0) {
                size_t n = (size_t) op_array->last_var;
                size_t pos = 0; pos += snprintf(cvmap_buf+pos, sizeof(cvmap_buf)-pos, "cvmap=");
                for (size_t i=0; i<n && pos < sizeof(cvmap_buf)-8; i++) {
                    const char *vn = ZSTR_VAL(op_array->vars[i]);
                    pos += snprintf(cvmap_buf+pos, sizeof(cvmap_buf)-pos, "%zu:%s%s", i, vn ? vn : "", (i+1<n?",":""));
                }
            }
            char branch_buf[128]; branch_buf[0] = '\0';
            if (opcode_tracer_is_jump_opcode(opline->opcode)) {
#if ZEND_USE_ABS_JMP_ADDR
                if (op_array && opidx >= 0) {
                    target_idx = opcode_tracer_get_jump_target(op_array->opcodes, opline, opidx);
                }
                if (target_idx >= 0) {
                    snprintf(branch_buf, sizeof(branch_buf), "branch=%s:%ld", opname ? opname : "", target_idx);
                }
#else
                long off = (long) opline->op2.jmp_offset;
                snprintf(branch_buf, sizeof(branch_buf), "branch=%s:%ld", opname ? opname : "", off);
                if (op_array && opidx >= 0) {
                    target_idx = opcode_tracer_get_jump_target(op_array->opcodes, opline, opidx);
                }
#endif
            }
            char ternary_buf[64]; ternary_buf[0] = '\0';
            if (opline->opcode == ZEND_QM_ASSIGN) {
                snprintf(ternary_buf, sizeof(ternary_buf), "ternary=QM_ASSIGN");
            }
            fprintf(trace_fp, "%s:%d | op=%s", path_out, opline->lineno, opname ? opname : "");
            if (opidx >= 0) fprintf(trace_fp, " | pc=%ld", opidx);
            if (o1[0]) fprintf(trace_fp, " | o1=%s", o1);
            if (o2[0]) fprintf(trace_fp, " | o2=%s", o2);
            if (res[0]) fprintf(trace_fp, " | res=%s", res);
            if (funcname) fprintf(trace_fp, " | func=%s", funcname);
            if (is_entry && funcname) fprintf(trace_fp, " | entry=%s", funcname);
            if (cvmap_buf[0]) fprintf(trace_fp, " | %s", cvmap_buf);
            if (branch_buf[0]) fprintf(trace_fp, " | %s", branch_buf);
            if (target_idx >= 0) fprintf(trace_fp, " | bpc=%ld", target_idx);
            if (ternary_buf[0]) fprintf(trace_fp, " | %s", ternary_buf);
            fprintf(trace_fp, "\n");
        }
    }
    
    return ZEND_USER_OPCODE_DISPATCH;
}

PHP_MINIT_FUNCTION(opcode_tracer)
{
    char *trace_log = getenv("OPCODE_TRACE");
    if (trace_log) {
        trace_fp = fopen(trace_log, "w");
        if (trace_fp) {
            setbuf(trace_fp, NULL);
        }
    }
    {
        char *p = getenv("OPCODE_TRACE_ONLY_PREFIX");
        if (p && *p) {
            strncpy(only_prefix, p, sizeof(only_prefix)-1);
            only_prefix[sizeof(only_prefix)-1] = '\0';
        }
    }
    
    /* Register handlers for all VM opcodes known by the current PHP build. */
    {
        zend_uchar i;
        for (i = 0; i <= ZEND_VM_LAST_OPCODE; i++) {
            zend_set_user_opcode_handler(i, opcode_tracer_handler);
        }
    }
    
    return SUCCESS;
}

PHP_MSHUTDOWN_FUNCTION(opcode_tracer)
{
    if (trace_fp) {
        fclose(trace_fp);
        trace_fp = NULL;
    }
    return SUCCESS;
}

PHP_MINFO_FUNCTION(opcode_tracer)
{
    php_info_print_table_start();
    php_info_print_table_header(2, "opcode_tracer support", "enabled");
    php_info_print_table_row(2, "Version", PHP_OPCODE_TRACER_VERSION);
    php_info_print_table_end();
}

const zend_function_entry opcode_tracer_functions[] = {
    PHP_FE_END
};

zend_module_entry opcode_tracer_module_entry = {
    STANDARD_MODULE_HEADER,
    "opcode_tracer",
    opcode_tracer_functions,
    PHP_MINIT(opcode_tracer),
    PHP_MSHUTDOWN(opcode_tracer),
    NULL,
    NULL,
    PHP_MINFO(opcode_tracer),
    PHP_OPCODE_TRACER_VERSION,
    STANDARD_MODULE_PROPERTIES
};

#ifdef COMPILE_DL_OPCODE_TRACER
ZEND_GET_MODULE(opcode_tracer)
#endif
