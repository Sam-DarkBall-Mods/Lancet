let version = HEMTT.project().version().to_string();
let authority = "db_lancet_" + version;
let folder = HEMTT_OUT.join("addons");
let old_name = "db_lancet_lk_lancet";
let new_name = "lk_lancet";

let old_pbo = folder.join(old_name + ".pbo");
let new_pbo = folder.join(new_name + ".pbo");
if !old_pbo.move(new_pbo) {
    fatal("Failed to restore legacy PBO name for " + old_name);
}

let old_signature = folder.join(old_name + ".pbo." + authority + ".bisign");
let new_signature = folder.join(new_name + ".pbo." + authority + ".bisign");
if old_signature.exists() && !old_signature.move(new_signature) {
    fatal("Failed to restore legacy signature name for " + old_name);
}
