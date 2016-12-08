(* This file was generated by Ocsigen Start.
   Feel free to use it, modify it, and redistribute it as you wish. *)


(* Create a button to update set the email as main email *)
let%shared update_main_email_button email =
  let open Eliom_content.Html in
  let button =
    D.button ~a:[D.a_class ["button"]] [D.pcdata "Set as main e-mail"]
  in
  ignore [%client (Lwt.async (fun () ->
    Lwt_js_events.clicks
      (Eliom_content.Html.To_dom.of_element ~%button)
      (fun _ _ ->
        let%lwt () = Os_current_user.update_main_email ~%email in
        Eliom_client.change_page
          ~service:%%%MODULE_NAME%%%_services.settings_service () ()
      )
  ) : unit) ];
  button

(* Create a button to remove the email from the database *)
let%shared delete_email_button email =
  let open Eliom_content.Html in
  let button = D.button
      ~a:[D.a_class ["button" ; "remove-email-button"]]
      [%%%MODULE_NAME%%%_icons.D.icon ["fa-trash-o"] ()]
  in
  ignore [%client (Lwt.async (fun () ->
    Lwt_js_events.clicks
      (Eliom_content.Html.To_dom.of_element ~%button)
      (fun _ _ ->
        let%lwt () = Os_current_user.remove_email_from_user ~%email in
        Eliom_client.change_page
          ~service:%%%MODULE_NAME%%%_services.settings_service () ()
      )
  ) : unit) ];
  button

(* Return a list of buttons to update or to remove the email depending on the
   email properties
*)
let%shared buttons_of_email is_main_email is_validated email =
  if is_main_email
  then []
  else if is_validated
  then [update_main_email_button email ; delete_email_button email]
  else [delete_email_button email]

(* Return a list of labels describing the email properties. *)
let%shared labels_of_email is_main_email is_validated =
  let open Eliom_content.Html.F in
  let valid_label = span ~a: [a_class ["label" ; "validated-email"]] [
     pcdata @@
      if is_validated
      then "Validated"
      else "Waiting for confirmation"
  ] in
  if is_main_email
  then [span ~a:[a_class ["label" ; "main-email"]] [pcdata "Main e-mail"] ; valid_label]
  else [valid_label]

(* Return a list element for the given email *)
let%shared li_of_email main_email email =
  let open Eliom_content.Html.D in
  let%lwt is_validated = Os_current_user.is_email_validated email in
  let is_main_email = (main_email = email) in
  let labels = labels_of_email is_main_email is_validated in
  let buttons = buttons_of_email is_main_email is_validated email in
  let email = span [pcdata email] in
  Lwt.return @@ li (email :: labels @ buttons)

(* Return a list with information about emails *)
let%server ul_of_emails () : [`Ul] Eliom_content.Html.elt Lwt.t =
  let open Eliom_content.Html.F in
  let myid = Os_current_user.get_current_userid () in
  let%lwt main_email = Os_db.User.email_of_userid myid in
  let%lwt l = Os_db.User.emails_of_userid myid in
  let li_of_email = li_of_email main_email in
  let%lwt li_list = Lwt_list.map_s li_of_email l in
  Lwt.return @@ ul li_list

(* Return a list with information about emails *)
let%client ul_of_emails =
  ~%(Eliom_client.server_function [%derive.json : unit] ul_of_emails)

let%shared settings_content () =
  let none = [%client ((fun () -> ()) : unit -> unit)] in
  let%lwt emails = ul_of_emails () in
  Lwt.return @@
  Eliom_content.Html.D.(
    [
      div ~a:[a_class ["os-settings"]] [
        p [pcdata "Change your password:"];
        Os_view.password_form ~service:Os_services.set_password_service ();
        br ();
        Os_userbox.upload_pic_link
          none
          %%%MODULE_NAME%%%_services.upload_user_avatar_service;
        br ();
        Os_userbox.reset_tips_link none;
        br ();
        p [pcdata "Link a new email to your account:"];
        Os_view.generic_email_form ~service:Os_services.add_email_service ();
        p [pcdata "Currently registered emails:"];
        div ~a:[a_class ["os-emails"]] [emails]
      ]
    ]
  )
