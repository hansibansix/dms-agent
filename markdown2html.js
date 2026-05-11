.pragma library
// Markdown to HTML converter for AI Assistant plugin
// Supports headers, bold, italic, strikethrough, code blocks with language labels,
// tables, task lists, links, blockquotes, and horizontal rules

const SYNTAX_DEFAULT = {
    comment: "#7E8285",
    string:  "#A8E0A0",
    number:  "#C198F6",
    keyword: "#FF7BAC",
    builtin: "#7DCFFF"
};

const LANGS = {
    bash: { kw: ["if","then","else","elif","fi","for","in","do","done","while","case","esac","function","return","export","local","exit","break","continue","trap","set","read","source","alias","unalias"], builtin: ["echo","printf","cd","ls","cat","grep","sed","awk","cp","mv","rm","mkdir","rmdir","touch","chmod","chown","find","xargs","sudo","systemctl","journalctl","curl","wget","tar","git","make"], lc: "#" },
    sh:   "bash",
    zsh:  "bash",
    fish: "bash",
    js:   { kw: ["var","let","const","function","return","if","else","for","while","do","switch","case","break","continue","new","class","extends","super","this","null","undefined","true","false","typeof","instanceof","in","of","try","catch","finally","throw","async","await","yield","import","export","default","from","as"], builtin: ["console","Math","JSON","Object","Array","Promise","Date","RegExp","Number","String","Boolean","Symbol","window","document","require","module","exports"], lc: "//", bc: ["/*","*/"] },
    javascript: "js",
    ts: { kw: ["var","let","const","function","return","if","else","for","while","do","switch","case","break","continue","new","class","extends","super","this","null","undefined","true","false","typeof","instanceof","in","of","try","catch","finally","throw","async","await","yield","import","export","default","from","as","interface","type","enum","public","private","protected","readonly","abstract","implements","keyof","never","unknown","any","void"], builtin: ["console","Math","JSON","Object","Array","Promise","Date","RegExp","Number","String","Boolean","Symbol"], lc: "//", bc: ["/*","*/"] },
    typescript: "ts",
    python: { kw: ["def","class","return","if","elif","else","for","while","in","not","and","or","is","None","True","False","import","from","as","with","try","except","finally","raise","pass","break","continue","lambda","yield","global","nonlocal","async","await","del"], builtin: ["print","len","range","str","int","float","list","dict","tuple","set","map","filter","zip","sorted","enumerate","open","isinstance","type","input","abs","min","max","sum","any","all","repr","hasattr","getattr","setattr"], lc: "#" },
    py: "python",
    json: { kw: ["true","false","null"] },
    qml:  { kw: ["import","property","signal","function","return","if","else","for","while","var","let","const","true","false","null","undefined","readonly","alias","component","pragma","required","default"], builtin: ["Item","Rectangle","Text","TextEdit","TextInput","Image","MouseArea","Component","Connections","Binding","Loader","ListView","Repeater","Column","Row","Grid","Flickable","ColumnLayout","RowLayout","GridLayout","Theme","Qt"], lc: "//", bc: ["/*","*/"] },
    c:    { kw: ["int","char","short","long","float","double","void","unsigned","signed","const","static","extern","volatile","return","if","else","for","while","do","switch","case","break","continue","goto","sizeof","struct","union","enum","typedef","NULL","true","false"], lc: "//", bc: ["/*","*/"] },
    cpp:  { kw: ["int","char","short","long","float","double","void","unsigned","signed","const","constexpr","static","extern","volatile","return","if","else","for","while","do","switch","case","break","continue","goto","sizeof","struct","union","enum","typedef","class","public","private","protected","virtual","override","final","template","typename","namespace","using","new","delete","this","nullptr","true","false","try","catch","throw","auto"], lc: "//", bc: ["/*","*/"] },
    "c++": "cpp",
    go:   { kw: ["func","return","if","else","for","range","break","continue","switch","case","default","package","import","var","const","type","struct","interface","map","chan","go","select","defer","fallthrough","nil","true","false"], builtin: ["fmt","println","print","len","cap","make","new","append","copy","delete","panic","recover","string","int","int32","int64","float32","float64","bool","byte","rune","error"], lc: "//", bc: ["/*","*/"] },
    rust: { kw: ["fn","let","mut","const","static","return","if","else","for","while","loop","match","break","continue","struct","enum","impl","trait","pub","use","mod","crate","self","super","as","ref","move","where","unsafe","async","await","dyn","true","false"], builtin: ["Box","Vec","Option","Result","Some","None","Ok","Err","String","str","i32","i64","u32","u64","f32","f64","bool","char","usize","isize","println","print","format","vec"], lc: "//", bc: ["/*","*/"] },
    rs:   "rust",
    sql:  { kw: ["select","from","where","insert","into","values","update","set","delete","create","table","drop","alter","add","column","primary","key","foreign","references","not","null","default","index","view","join","left","right","inner","outer","on","as","and","or","in","like","between","group","by","order","having","limit","offset","union","case","when","then","else","end","distinct","exists","with"], builtin: ["int","integer","varchar","char","text","date","datetime","timestamp","boolean","bool","float","double","decimal","numeric","blob"], lc: "--", bc: ["/*","*/"] },
    php:  { kw: ["if","else","elseif","endif","for","endfor","foreach","endforeach","while","endwhile","do","switch","endswitch","case","break","continue","default","return","exit","die","function","class","interface","trait","extends","implements","abstract","final","public","private","protected","static","const","var","namespace","use","as","new","throw","try","catch","finally","global","echo","print","include","require","include_once","require_once","yield","fn","match","readonly","enum","instanceof","clone","self","parent","this","null","true","false","and","or","xor","array","list","isset","unset","empty","declare","goto"], builtin: ["int","integer","string","bool","boolean","float","double","void","mixed","callable","iterable","object","never","count","strlen","strpos","str_replace","str_contains","str_starts_with","str_ends_with","sprintf","printf","var_dump","print_r","json_encode","json_decode","file_get_contents","file_put_contents","in_array","array_map","array_filter","array_keys","array_values","array_merge","array_push","array_pop","explode","implode","trim","substr","preg_match","preg_replace","preg_split","date","time","strtotime","intval","floatval","strval","is_array","is_string","is_int","is_null","is_object","is_callable","Exception","Throwable","ArrayObject","DateTime","DateTimeImmutable","Closure","Generator"], lc: ["//","#"], bc: ["/*","*/"] },
    php3: "php",
    php5: "php",
    php7: "php",
    php8: "php",
    css:  { kw: ["important"], builtin: ["px","em","rem","pt","pc","ex","ch","vh","vw","vmin","vmax","%","auto","none","inherit","initial","unset","absolute","relative","fixed","static","sticky","block","inline","flex","grid"], bc: ["/*","*/"] },
    diff: { kw: [] }
};

function _escHtml(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function _reEsc(s) {
    return s.replace(/[\\^$.*+?()[\]{}|]/g, '\\$&');
}

function highlightCode(code, lang, palette) {
    const c = palette || SYNTAX_DEFAULT;
    let def = LANGS[lang];
    if (typeof def === "string") def = LANGS[def];
    if (!def) return _escHtml(code);

    const parts = [];
    if (def.bc) parts.push({ src: _reEsc(def.bc[0]) + "[\\s\\S]*?" + _reEsc(def.bc[1]), type: "comment" });
    if (def.lc) {
        const lcs = Array.isArray(def.lc) ? def.lc : [def.lc];
        parts.push({ src: "(?:" + lcs.map(_reEsc).join("|") + ")[^\\n]*", type: "comment" });
    }
    parts.push({ src: '"(?:\\\\.|[^"\\\\\\n])*"',                                          type: "string" });
    parts.push({ src: "'(?:\\\\.|[^'\\\\\\n])*'",                                          type: "string" });
    parts.push({ src: '\\b\\d+(?:\\.\\d+)?\\b',                                            type: "number" });
    if (def.kw && def.kw.length)      parts.push({ src: '\\b(?:' + def.kw.join('|')      + ')\\b', type: "keyword" });
    if (def.builtin && def.builtin.length) parts.push({ src: '\\b(?:' + def.builtin.join('|') + ')\\b', type: "builtin" });

    const re = new RegExp(parts.map(p => "(" + p.src + ")").join("|"), "gm");
    let result = "";
    let last = 0;
    let m;
    while ((m = re.exec(code)) !== null) {
        if (m[0].length === 0) { re.lastIndex++; continue; }
        result += _escHtml(code.slice(last, m.index));
        const txt = _escHtml(m[0]);
        let type = null;
        for (let i = 0; i < parts.length; i++) {
            if (m[i + 1] !== undefined) { type = parts[i].type; break; }
        }
        result += (type && c[type]) ? '<span style="color: ' + c[type] + '">' + txt + '</span>' : txt;
        last = m.index + m[0].length;
    }
    result += _escHtml(code.slice(last));
    return result;
}

// Look up the Nth fenced code block in raw markdown text. Used by the
// chat UI to retrieve the original code when the user clicks a COPY link
// in the rendered HTML, since the HTML body itself is post-processed.
function extractCodeBlock(text, index) {
    if (!text || typeof index !== "number") return "";
    let i = 0;
    let result = "";
    text.replace(/```(?:[^\n]*\n)?([\s\S]*?)```/g, (match, code) => {
        if (i === index) result = (code || "").replace(/^\n+|\n+$/g, '');
        i++;
        return match;
    });
    return result;
}

function markdownToHtml(text, colors) {
    if (!text) return "";

    const c = colors || {
        codeBg: "#20FFFFFF",
        inlineCodeBg: "#30FFFFFF",
        blockquoteBg: "transparent",
        blockquoteBorder: "#808080"
    };

    // Store code blocks and inline code to protect them from further processing
    const codeBlocks = [];
    const inlineCode = [];
    const protectedBlocks = [];
    let blockIndex = 0;
    let inlineIndex = 0;
    let protectedIndex = 0;

    const codeFont       = c.codeFont       || "monospace";
    const codeBorder     = c.codeBorder     || "#33808080";
    const codeDivider    = c.codeDivider    || "#33808080";
    const codeLabelColor = c.codeLabelColor || "#80FFFFFF";
    const codeCopyColor  = c.codeCopyColor  || "#7DCFFF";

    // First, extract and replace code blocks with placeholders
    // Regex matches ```[language]\n[content]```
    let html = text.replace(/```(?:([^\n]*)\n)?([\s\S]*?)```/g, (match, lang, code) => {
        const trimmedCode = (code || "").replace(/^\n+|\n+$/g, '');
        const langName = (lang || "").trim().toLowerCase();
        // Use <br/> for line breaks inside <pre>. Qt's RichText only extends
        // the parent <div>'s background behind <br/>-separated lines — raw \n
        // inside <pre> renders without the background tint past the first line.
        const highlighted = highlightCode(trimmedCode, langName, c.syntax).replace(/\n/g, '<br/>');
        const blockIdx = blockIndex;

        // Header sits OUTSIDE the tinted code container — no background tint
        // on the label/COPY line; only the code area below has the codeBg.
        // Click on COPY is intercepted by TextEdit.onLinkActivated via the
        // dmsagent-copy:<index> URL scheme; the QML side re-extracts the
        // code from the original message by the given index.
        const labelSpan = langName
            ? `<span style="color: ${codeLabelColor}; letter-spacing: 1.5px;">${langName.toUpperCase()}</span>&nbsp;&nbsp;·&nbsp;&nbsp;`
            : '';
        const header = `<p style="margin: 12px 0 4px 0; padding: 0; font-family: ${codeFont}; font-size: 9px;">` +
            labelSpan +
            `<a href="dmsagent-copy:${blockIdx}" style="color: ${codeCopyColor}; text-decoration: none; letter-spacing: 1.5px;">COPY</a>` +
        `</p>`;

        codeBlocks.push(`${header}<div style="background-color: ${c.codeBg}; padding: 12px 14px; margin: 0 0 12px 0; border: 1px solid ${codeBorder}; border-radius: 8px;"><pre style="margin: 0; font-family: ${codeFont}; font-size: 12px; white-space: pre-wrap;"><code style="font-family: ${codeFont};">${highlighted}</code></pre></div>`);
        return `\x00CODEBLOCK${blockIndex++}\x00`;
    });

    // Extract and replace inline code
    html = html.replace(/`([^`]+)`/g, (match, code) => {
        const escapedCode = code.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
        inlineCode.push(`<span style="font-family: ${codeFont}; background-color: ${c.inlineCodeBg};">&nbsp;${escapedCode}&nbsp;</span>`);
        return `\x00INLINECODE${inlineIndex++}\x00`;
    });

    // Extract and protect tables BEFORE HTML entity escaping
    html = html.replace(/^\|(.+)\|\s*\n\|[\s\-:|]+\|\s*\n((?:\|.+\|\s*\n?)+)/gm, function(match, headerRow, dataRows) {
        // Parse header
        const headers = headerRow.split('|').map(h => h.trim()).filter(h => h);

        // Parse data rows
        const rows = dataRows.trim().split('\n').map(row => {
            return row.split('|').map(cell => cell.trim()).filter(cell => cell !== '');
        });

        // Build HTML table
        let tableHtml = '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse; margin: 8px 0;">';

        // Add header
        tableHtml += '<tr>';
        headers.forEach(header => {
            tableHtml += `<th style="background-color: #30FFFFFF; padding: 5px;">${header}</th>`;
        });
        tableHtml += '</tr>';

        // Add data rows
        rows.forEach(row => {
            tableHtml += '<tr>';
            row.forEach(cell => {
                tableHtml += `<td style="padding: 5px;">${cell}</td>`;
            });
            tableHtml += '</tr>';
        });

        tableHtml += '</table>';

        // Protect table from further processing
        protectedBlocks.push(tableHtml);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Now process everything else
    // Escape HTML entities (but not in code blocks or tables)
    html = html.replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');

    // Headers
    // Use <font size> to force sizing as QML CSS support for headers is flaky
    // Add margin-bottom for spacing instead of <br/> to avoid cleanup issues
    // Use [\s\S]*? instead of .*? to handle any whitespace at end of line
    html = html.replace(/^######\s+([\s\S]*?)$/gm, '<h6 style="margin-bottom: 8px;"><font size="2">$1</font></h6>');
    html = html.replace(/^#####\s+([\s\S]*?)$/gm, '<h5 style="margin-bottom: 8px;"><i><font size="3">$1</font></i></h5>');
    html = html.replace(/^####\s+([\s\S]*?)$/gm, '<h4 style="margin-bottom: 8px;"><font size="3">$1</font></h4>');
    html = html.replace(/^###\s+([\s\S]*?)$/gm, '<h3 style="margin-bottom: 8px;"><font size="4">$1</font></h3>');
    html = html.replace(/^##\s+([\s\S]*?)$/gm, '<h2 style="margin-bottom: 8px;"><font size="5">$1</font></h2>');
    html = html.replace(/^#\s+([\s\S]*?)$/gm, '<h1 style="margin-bottom: 10px;"><font size="6">$1</font></h1>');

    // Horizontal Rule (3 or more dashes/stars/underscores on a line)
    // Must be before bold/italic/lists to prevent interference
    html = html.replace(/^(\*{3,}|-{3,}|_{3,})$/gm, '<hr style="margin: 12px 0;"/>');

    // Bold and italic (order matters!)
    html = html.replace(/\*\*\*(.*?)\*\*\*/g, '<b><i>$1</i></b>');
    html = html.replace(/\*\*(.*?)\*\*/g, '<b>$1</b>');
    html = html.replace(/\*(.*?)\*/g, '<i>$1</i>');
    html = html.replace(/___(.*?)___/g, '<b><i>$1</i></b>');
    html = html.replace(/__(.*?)__/g, '<b>$1</b>');
    html = html.replace(/_(.*?)_/g, '<i>$1</i>');

    // Strikethrough
    html = html.replace(/~~(.*?)~~/g, '<s>$1</s>');

    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');

    // Task Lists (must be before regular lists)
    // Match - [ ] or - [x] or - [X]
    html = html.replace(/^\s*[\*\-] \[([ xX])\] (.*?)$/gm, function(match, checked, content) {
        const checkbox = checked.toLowerCase() === 'x' ? '☑' : '☐';
        return `<li_task>${checkbox} ${content}</li_task>`;
    });

    // Lists - Differentiate UL and OL
    // Replace * - with <li_ul>
    html = html.replace(/^\s*[\*\-] (.*?)$/gm, '<li_ul>$1</li_ul>');
    // Replace 1. with <li_ol>
    html = html.replace(/^\s*\d+\. (.*?)$/gm, '<li_ol>$1</li_ol>');

    // Wrap consecutive list items and EXTRACT them to protect from newline processing
    // Unordered
    html = html.replace(/(<li_ul>[\s\S]*?<\/li_ul>\s*)+/g, function(match) {
        // Strip newlines inside the list block to avoid double spacing later
        const content = match.replace(/<\/?li_ul>/g, (tag) => tag.replace('li_ul', 'li')).replace(/\n/g, '');
        const block = `<ul style="margin: 8px 0;">${content}</ul>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Ordered
    html = html.replace(/(<li_ol>[\s\S]*?<\/li_ol>\s*)+/g, function(match) {
        const content = match.replace(/<\/?li_ol>/g, (tag) => tag.replace('li_ol', 'li')).replace(/\n/g, '');
        const block = `<ol style="margin: 8px 0;">${content}</ol>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Task Lists
    html = html.replace(/(<li_task>[\s\S]*?<\/li_task>\s*)+/g, function(match) {
        const content = match.replace(/<\/?li_task>/g, (tag) => tag.replace('li_task', 'li')).replace(/\n/g, '');
        const block = `<ul style="list-style-type: none; margin: 8px 0;">${content}</ul>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Blockquotes
    // Note: '>' is already escaped to '&gt;'
    html = html.replace(/^&gt; (.*?)$/gm, '<bq_line>$1</bq_line>');
    html = html.replace(/(<bq_line>[\s\S]*?<\/bq_line>\s*)+/g, function(match) {
        // Merge content, replacing closing/opening tags with BR
        // <bq_line>A</bq_line>\n<bq_line>B</bq_line> -> A<br/>B
        const inner = match.replace(/<\/bq_line>\s*<bq_line>/g, '<br/>')
                           .replace(/<bq_line>/g, '')
                           .replace(/<\/bq_line>/g, '')
                           .trim();
        // Use blockquote tag (supported by QML for indentation) and add styling
        const block = `<blockquote style="background-color: ${c.blockquoteBg}; border-left: 4px solid ${c.blockquoteBorder}; padding: 4px; margin: 8px 0;"><font color="#a0a0a0"><i>${inner}</i></font></blockquote>`;
        protectedBlocks.push(block);
        return `\x00PROTECTEDBLOCK${protectedIndex++}\x00\n`;
    });

    // Detect plain URLs and wrap them in anchor tags (but not inside existing <a> or markdown links)
    html = html.replace(/(^|[^"'>])((https?|file):\/\/[^\s<]+)/g, '$1<a href="$2">$2</a>');

    // Inline code has no embedded newlines, so it's safe to restore before
    // line-break processing.
    html = html.replace(/\x00INLINECODE(\d+)\x00/g, (match, index) => {
        return inlineCode[parseInt(index)];
    });

    // Line breaks
    html = html.replace(/\n\n/g, '</p><p>');
    html = html.replace(/\n/g, '<br/>');

    // Wrap in paragraph tags if not already wrapped
    if (!html.startsWith('<') && !html.startsWith('\x00')) {
        html = '<p>' + html + '</p>';
    }

    // Restore PROTECTED blocks (Lists, Blockquotes, Tables) AFTER line break processing
    html = html.replace(/\x00PROTECTEDBLOCK(\d+)\x00/g, (match, index) => {
        return protectedBlocks[parseInt(index)];
    });

    // Restore code blocks LAST. They must survive the \n\n → </p><p> pass
    // intact — otherwise a blank line inside a fenced block would split the
    // styled <div><pre>...</pre></div> wrapper and only the first chunk would
    // keep the header (lang label + COPY).
    html = html.replace(/\x00CODEBLOCK(\d+)\x00/g, (match, index) => codeBlocks[parseInt(index)]);

    // Inline code can also appear inside protected blocks (e.g. table cells);
    // restore any remaining placeholders now.
    html = html.replace(/\x00INLINECODE(\d+)\x00/g, (match, index) => inlineCode[parseInt(index)]);

    // Strip <p>...</p> wrappers around <div> code blocks. The earlier line-break
    // pass turns text + code into "<p>text</p><p><div>...</div></p>", but Qt's
    // RichText renders <p><div>...</div></p> with an empty paragraph above the
    // block. Pulling the div out of the paragraph removes that visual gap.
    html = html.replace(/<p>\s*(<div[^>]*>[\s\S]*?<\/div>)\s*<\/p>/g, '$1');

    // Clean up the final HTML
    // Remove <br/> tags immediately before block elements
    html = html.replace(/<br\/>\s*(<pre>)/g, '$1');
    html = html.replace(/<br\/>\s*(<ul[^>]*>)/g, '$1');
    html = html.replace(/<br\/>\s*(<ol[^>]*>)/g, '$1');
    html = html.replace(/<br\/>\s*(<blockquote[^>]*>)/g, '$1');
    html = html.replace(/<br\/>\s*(<table[^>]*>)/g, '$1');
    html = html.replace(/<br\/>\s*(<h[1-6][^>]*>)/g, '$1');
    html = html.replace(/<br\/>\s*(<div[^>]*>)/g, '$1');
    html = html.replace(/(<\/div>)\s*<br\/>/g, '$1');

    // Remove empty paragraphs
    html = html.replace(/<p>\s*<\/p>/g, '');
    html = html.replace(/<p>\s*<br\/>\s*<\/p>/g, '');

    // Remove excessive line breaks
    html = html.replace(/(<br\/>){3,}/g, '<br/><br/>'); // Max 2 consecutive line breaks
    html = html.replace(/(<\/p>)\s*(<p>)/g, '$1$2'); // Remove whitespace between paragraphs

    // Remove leading/trailing whitespace
    html = html.trim();

    return html;
}
